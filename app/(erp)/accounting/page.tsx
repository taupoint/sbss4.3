'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { formatCurrency } from '@/lib/format';
import { DollarSign, CreditCard, TrendingUp, TrendingDown, ChartBar as BarChart3 } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import type { Account } from '@/lib/types';

export default function AccountingPage() {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    const { data } = await supabase.from('accounts').select('*').eq('is_active', true).order('code');
    setAccounts(data || []);
    setLoading(false);
  }

  const assets = accounts.filter(a => a.account_type === 'asset');
  const liabilities = accounts.filter(a => a.account_type === 'liability');
  const revenue = accounts.filter(a => a.account_type === 'revenue');
  const expenses = accounts.filter(a => a.account_type === 'expense');

  const totalAssets = assets.reduce((s, a) => s + Number(a.balance), 0);
  const totalLiabilities = liabilities.reduce((s, a) => s + Number(a.balance), 0);
  const totalRevenue = revenue.reduce((s, a) => s + Number(a.balance), 0);
  const totalExpenses = expenses.reduce((s, a) => s + Number(a.balance), 0);
  const netProfit = totalRevenue - totalExpenses;
  const equity = totalAssets - totalLiabilities;

  // Group revenue/expense by month for chart (using last 6 months from journal entries)
  const [monthlyData, setMonthlyData] = useState<{ month: string; income: number; expense: number }[]>([]);

  useEffect(() => {
    async function loadMonthlyData() {
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
      sixMonthsAgo.setDate(1);

      const { data: entries } = await supabase
        .from('journal_entries')
        .select('entry_date, total_debit, total_credit, lines:journal_lines(account:accounts(account_type))')
        .gte('entry_date', sixMonthsAgo.toISOString().split('T')[0])
        .order('entry_date');

      if (!entries) return;

      const monthMap = new Map<string, { income: number; expense: number }>();
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      entries.forEach((entry: any) => {
        const date = new Date(entry.entry_date);
        const monthKey = monthNames[date.getMonth()];

        // Simplified: use reference to determine if income or expense
        // Revenue entries credit revenue accounts, expense entries debit expense accounts
        if (!monthMap.has(monthKey)) {
          monthMap.set(monthKey, { income: 0, expense: 0 });
        }

        const monthData = monthMap.get(monthKey)!;
        // For simplicity, credit to revenue accounts is income
        // Debit to expense accounts is expense
        if (entry.reference_type === 'invoice') {
          monthData.income += Number(entry.total_credit);
        } else if (entry.reference_type === 'payment') {
          // Payment is just moving between accounts, not revenue
        }
      });

      // If no data, show placeholder
      if (monthMap.size === 0) {
        setMonthlyData([
          { month: 'Jan', income: 0, expense: 0 },
          { month: 'Feb', income: 0, expense: 0 },
          { month: 'Mar', income: 0, expense: 0 },
          { month: 'Apr', income: 0, expense: 0 },
          { month: 'May', income: 0, expense: 0 },
          { month: 'Jun', income: 0, expense: 0 },
        ]);
      } else {
        setMonthlyData(Array.from(monthMap.entries()).map(([month, data]) => ({
          month,
          income: data.income,
          expense: data.expense,
        })));
      }
    }
    loadMonthlyData();
  }, []);

  const typeColors: Record<string, string> = {
    asset: 'text-blue-600 bg-blue-50',
    liability: 'text-red-600 bg-red-50',
    equity: 'text-purple-600 bg-purple-50',
    revenue: 'text-green-600 bg-green-50',
    expense: 'text-orange-600 bg-orange-50',
  };

  return (
    <div className="space-y-5 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Accounting</h1>
          <p className="text-muted-foreground text-sm mt-0.5">Financial overview with automated double-entry</p>
        </div>
      </div>

      {/* Financial Summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Total Assets', value: totalAssets, icon: DollarSign, color: 'text-blue-500 bg-blue-50' },
          { label: 'Total Liabilities', value: totalLiabilities, icon: CreditCard, color: 'text-red-500 bg-red-50' },
          { label: 'Revenue', value: totalRevenue, icon: TrendingUp, color: 'text-green-500 bg-green-50' },
          { label: 'Net Profit', value: netProfit, icon: BarChart3, color: netProfit >= 0 ? 'text-purple-500 bg-purple-50' : 'text-red-500 bg-red-50' },
        ].map(s => (
          <div key={s.label} className="stat-card">
            <div className="flex items-center justify-between mb-2">
              <div className={`w-9 h-9 rounded-full flex items-center justify-center ${s.color}`}>
                <s.icon className="w-4.5 h-4.5" />
              </div>
            </div>
            <p className="text-xs text-muted-foreground">{s.label}</p>
            <p className={`text-xl font-bold mt-0.5 ${Number(s.value) >= 0 ? 'text-foreground' : 'text-red-600'}`}>
              {formatCurrency(Math.abs(Number(s.value)))}
            </p>
          </div>
        ))}
      </div>

      {/* Income vs Expense Chart */}
      <div className="bg-white rounded-xl border border-border p-5 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold text-foreground">Revenue Overview</h3>
          <span className="text-xs text-muted-foreground">Last 6 months</span>
        </div>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={monthlyData} barSize={20} barGap={4}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
            <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} tickFormatter={v => v >= 1000 ? `${(v/1000).toFixed(0)}K` : v} />
            <Tooltip formatter={(v: number) => [formatCurrency(v), '']} contentStyle={{ fontSize: 12, borderRadius: 8 }} />
            <Bar dataKey="income" fill="#10b981" radius={[4, 4, 0, 0]} name="Revenue" />
            <Bar dataKey="expense" fill="#ef4444" radius={[4, 4, 0, 0]} name="Expenses" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Chart of Accounts */}
      <div className="table-wrapper">
        <div className="px-4 py-3 border-b border-border flex items-center justify-between">
          <h3 className="text-sm font-semibold text-foreground">Chart of Accounts</h3>
          <span className="text-xs text-muted-foreground">{accounts.length} active accounts</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="bg-muted/40 border-b border-border">
                <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Code</th>
                <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Account Name</th>
                <th className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">Type</th>
                <th className="text-right text-xs font-semibold text-muted-foreground px-4 py-3">Balance</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array.from({ length: 8 }).map((_, i) => (
                  <tr key={i}>
                    {Array.from({ length: 4 }).map((_, j) => (
                      <td key={j} className="px-4 py-3"><div className="h-4 bg-muted rounded animate-pulse" /></td>
                    ))}
                  </tr>
                ))
              ) : accounts.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-4 py-8 text-center text-muted-foreground text-sm">
                    No accounts configured. Accounts are created automatically when transactions occur.
                  </td>
                </tr>
              ) : (
                accounts.map(a => (
                  <tr key={a.id} className="hover:bg-muted/30 transition-colors">
                    <td className="px-4 py-3 text-sm font-mono text-muted-foreground">{a.code}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium text-foreground">{a.name}</span>
                        {a.is_cash && <span className="badge-status bg-green-50 text-green-600">Cash</span>}
                        {a.is_bank && <span className="badge-status bg-blue-50 text-blue-600">Bank</span>}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`badge-status ${typeColors[a.account_type] || 'bg-gray-100 text-gray-600'} capitalize`}>
                        {a.account_type}
                      </span>
                    </td>
                    <td className={`px-4 py-3 text-right text-sm font-bold ${
                      a.account_type === 'expense' ? 'text-red-600' :
                      a.account_type === 'liability' ? 'text-red-600' :
                      'text-green-600'
                    }`}>
                      {formatCurrency(Math.abs(Number(a.balance)))}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
