'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { formatCurrency, formatDate } from '@/lib/format';
import { Plus, ChevronDown, ChevronRight, FileText, Receipt, CreditCard, Package, ArrowRightLeft, ShoppingBag } from 'lucide-react';

interface JournalLine {
  id: string;
  account_id: string;
  account: { code: string; name: string; account_type: string } | { code: string; name: string; account_type: string }[];
  description: string;
  debit: number;
  credit: number;
}

interface JournalEntry {
  id: string;
  entry_number: string;
  entry_date: string;
  description: string;
  reference_type: string | null;
  reference_id: string | null;
  total_debit: number;
  total_credit: number;
  is_posted: boolean;
  created_at: string;
  lines?: JournalLine[];
}

const refIcons: Record<string, React.ElementType> = {
  invoice: Receipt,
  payment: CreditCard,
  grn: Package,
  sales_return: ArrowRightLeft,
  purchase_return: ShoppingBag,
};

const refLabels: Record<string, string> = {
  invoice: 'Invoice',
  payment: 'Payment',
  grn: 'Goods Receipt',
  sales_return: 'Sales Return',
  purchase_return: 'Purchase Return',
};

export default function JournalPage() {
  const [entries, setEntries] = useState<JournalEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    const { data } = await supabase
      .from('journal_entries')
      .select('*')
      .order('entry_date', { ascending: false })
      .order('created_at', { ascending: false })
      .limit(100);
    setEntries(data || []);
    setLoading(false);
  }

  async function toggleExpand(id: string) {
    if (expandedId === id) {
      setExpandedId(null);
      return;
    }

    // Load lines if not already loaded
    const entry = entries.find(e => e.id === id);
    if (!entry?.lines) {
      const { data: lines } = await supabase
        .from('journal_lines')
        .select('id, account_id, description, debit, credit, account:accounts(code, name, account_type)')
        .eq('journal_entry_id', id)
        .order('sort_order');

      setEntries(prev => prev.map(e =>
        e.id === id ? { ...e, lines: lines || [] } : e
      ));
    }
    setExpandedId(id);
  }

  return (
    <div className="space-y-5 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Journal Entries</h1>
          <p className="text-muted-foreground text-sm mt-0.5">Double-entry accounting ledger with automatic posting</p>
        </div>
        <button className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-semibold transition">
          <Plus className="w-4 h-4" />Manual Entry
        </button>
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="stat-card">
          <p className="text-xs text-muted-foreground">Total Entries</p>
          <p className="text-xl font-bold text-foreground">{entries.length}</p>
        </div>
        <div className="stat-card">
          <p className="text-xs text-muted-foreground">Posted</p>
          <p className="text-xl font-bold text-green-600">{entries.filter(e => e.is_posted).length}</p>
        </div>
        <div className="stat-card">
          <p className="text-xs text-muted-foreground">Total Debits</p>
          <p className="text-xl font-bold text-blue-600">{formatCurrency(entries.reduce((s, e) => s + Number(e.total_debit), 0))}</p>
        </div>
        <div className="stat-card">
          <p className="text-xs text-muted-foreground">Total Credits</p>
          <p className="text-xl font-bold text-red-600">{formatCurrency(entries.reduce((s, e) => s + Number(e.total_credit), 0))}</p>
        </div>
      </div>

      <div className="table-wrapper">
        <table className="w-full">
          <thead>
            <tr className="bg-muted/40 border-b border-border">
              <th className="w-8"></th>
              <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Entry #</th>
              <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Date</th>
              <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Description</th>
              <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Reference</th>
              <th className="text-right text-xs font-semibold text-muted-foreground px-4 py-3">Debit</th>
              <th className="text-right text-xs font-semibold text-muted-foreground px-4 py-3">Credit</th>
              <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {loading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <tr key={i}>
                  {Array.from({ length: 8 }).map((_, j) => (
                    <td key={j} className="px-4 py-3">
                      <div className="h-4 bg-muted rounded animate-pulse" />
                    </td>
                  ))}
                </tr>
              ))
            ) : entries.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-4 py-12 text-center text-muted-foreground text-sm">
                  <FileText className="w-12 h-12 mx-auto mb-3 text-muted-foreground/40" />
                  No journal entries yet. Entries are automatically created when you confirm invoices, receive payments, or process returns.
                </td>
              </tr>
            ) : (
              entries.map((entry) => (
                <>
                  <tr
                    key={entry.id}
                    className="hover:bg-muted/30 transition-colors cursor-pointer"
                    onClick={() => toggleExpand(entry.id)}
                  >
                    <td className="px-2 py-3">
                      {expandedId === entry.id ? (
                        <ChevronDown className="w-4 h-4 text-muted-foreground" />
                      ) : (
                        <ChevronRight className="w-4 h-4 text-muted-foreground" />
                      )}
                    </td>
                    <td className="px-4 py-3 text-sm font-semibold text-blue-600">{entry.entry_number}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">{formatDate(entry.entry_date)}</td>
                    <td className="px-4 py-3 text-sm text-foreground max-w-xs truncate">{entry.description}</td>
                    <td className="px-4 py-3">
                      {entry.reference_type && (
                        <span className="inline-flex items-center gap-1.5 text-xs">
                          {refIcons[entry.reference_type] && (
                            <span className="w-5 h-5 rounded bg-muted flex items-center justify-center">
                              {(() => {
                                const Icon = refIcons[entry.reference_type];
                                return <Icon className="w-3 h-3 text-muted-foreground" />;
                              })()}
                            </span>
                          )}
                          <span className="text-muted-foreground">{refLabels[entry.reference_type] || entry.reference_type}</span>
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-sm font-semibold text-green-600 text-right">{formatCurrency(entry.total_debit)}</td>
                    <td className="px-4 py-3 text-sm font-semibold text-red-600 text-right">{formatCurrency(entry.total_credit)}</td>
                    <td className="px-4 py-3">
                      <span className={`badge-status ${entry.is_posted ? 'bg-green-50 text-green-600' : 'bg-gray-100 text-gray-600'}`}>
                        {entry.is_posted ? 'Posted' : 'Draft'}
                      </span>
                    </td>
                  </tr>
                  {expandedId === entry.id && entry.lines && (
                    <tr key={`${entry.id}-lines`} className="bg-muted/20">
                      <td colSpan={8} className="px-4 py-3">
                        <div className="ml-8 space-y-1">
                          <div className="text-xs font-medium text-muted-foreground mb-2">Line Items</div>
                          <table className="w-full text-xs">
                            <thead>
                              <tr className="text-muted-foreground">
                                <th className="text-left py-1 font-medium">Account</th>
                                <th className="text-left py-1 font-medium">Description</th>
                                <th className="text-right py-1 font-medium">Debit</th>
                                <th className="text-right py-1 font-medium">Credit</th>
                              </tr>
                            </thead>
                            <tbody>
                              {entry.lines.map((line) => {
                                const acc = Array.isArray(line.account) ? line.account[0] : line.account;
                                return (
                                <tr key={line.id} className="text-foreground">
                                  <td className="py-1.5">
                                    <span className="font-mono text-muted-foreground mr-2">{acc?.code}</span>
                                    <span className="font-medium">{acc?.name}</span>
                                  </td>
                                  <td className="py-1.5 text-muted-foreground">{line.description || '-'}</td>
                                  <td className="py-1.5 text-right font-medium text-green-600">
                                    {Number(line.debit) > 0 ? formatCurrency(line.debit) : '-'}
                                  </td>
                                  <td className="py-1.5 text-right font-medium text-red-600">
                                    {Number(line.credit) > 0 ? formatCurrency(line.credit) : '-'}
                                  </td>
                                </tr>
                              );
                              })}
                            </tbody>
                          </table>
                        </div>
                      </td>
                    </tr>
                  )}
                </>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
