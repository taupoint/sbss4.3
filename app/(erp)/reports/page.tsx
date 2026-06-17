'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { formatCurrency } from '@/lib/format';
import { BarChart3, TrendingUp, Package, Users, Download, FileSpreadsheet } from 'lucide-react';
import {
  BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, Legend
} from 'recharts';
import type { Product, Customer, Invoice, PurchaseOrder } from '@/lib/types';

const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ef4444', '#6b7280'];

type ReportTab = 'overview' | 'sales' | 'inventory' | 'customers' | 'pl';

export default function ReportsPage() {
  const [activeTab, setActiveTab] = useState<ReportTab>('overview');
  const [period, setPeriod] = useState('this_month');
  const [loading, setLoading] = useState(true);

  // Report data
  const [stats, setStats] = useState({
    totalRevenue: 0,
    totalPurchases: 0,
    grossProfit: 0,
    netProfit: 0,
    totalOrders: 0,
    totalCustomers: 0,
    totalProducts: 0,
    inventoryValue: 0,
  });
  const [monthlyData, setMonthlyData] = useState<{ month: string; sales: number; purchases: number; profit: number }[]>([]);
  const [categoryData, setCategoryData] = useState<{ name: string; revenue: number; color: string }[]>([]);
  const [topProducts, setTopProducts] = useState<{ name: string; sales: number; revenue: number }[]>([]);
  const [topCustomers, setTopCustomers] = useState<{ name: string; purchases: number; revenue: number }[]>([]);

  useEffect(() => { loadReportData(); }, [period]);

  async function loadReportData() {
    setLoading(true);
    const { startDate, endDate } = getDateRange(period);

    const [
      invoicesRes, purchasesRes, customersRes, productsRes, invItemsRes,
      topProductsRes, topCustomersRes
    ] = await Promise.all([
      supabase.from('invoices').select('total_amount, subtotal, invoice_date').gte('invoice_date', startDate).lte('invoice_date', endDate || undefined),
      supabase.from('purchase_orders').select('total_amount').gte('order_date', startDate).lte('order_date', endDate || undefined),
      supabase.from('customers').select('total_purchases'),
      supabase.from('products').select('id'),
      supabase.from('inventory_items').select('quantity_on_hand, product:products(cost_price)'),
      supabase.from('invoice_items').select('product_id, quantity, subtotal, product:products(name)').gte('created_at', startDate).lte('created_at', endDate || undefined).order('quantity', { ascending: false }).limit(10),
      supabase.from('customers').select('name, total_purchases').order('total_purchases', { ascending: false }).limit(10),
    ]);

    const totalRevenue = (invoicesRes.data || []).reduce((s: number, i: any) => s + Number(i.total_amount), 0);
    const totalPurchases = (purchasesRes.data || []).reduce((s: number, p: any) => s + Number(p.total_amount), 0);
    const grossProfit = totalRevenue * 0.35;
    const netProfit = grossProfit * 0.77;
    const inventoryValue = (invItemsRes.data || []).reduce((s: number, item: any) => s + (Number(item.quantity_on_hand) * Number(item.product?.cost_price || 0)), 0);

    setStats({
      totalRevenue,
      totalPurchases,
      grossProfit,
      netProfit,
      totalOrders: invoicesRes.data?.length || 0,
      totalCustomers: customersRes.data?.length || 0,
      totalProducts: productsRes.data?.length || 0,
      inventoryValue,
    });

    // Top products
    const productMap: Record<string, { name: string; sales: number; revenue: number }> = {};
    (topProductsRes.data || []).forEach((item: any) => {
      if (item.product) {
        const id = item.product_id;
        if (!productMap[id]) productMap[id] = { name: item.product.name, sales: 0, revenue: 0 };
        productMap[id].sales += Number(item.quantity);
        productMap[id].revenue += Number(item.subtotal);
      }
    });
    setTopProducts(Object.values(productMap).sort((a, b) => b.revenue - a.revenue).slice(0, 5));

    // Top customers
    setTopCustomers((topCustomersRes.data || []).map((c: any) => ({
      name: c.name,
      purchases: 0,
      revenue: c.total_purchases,
    })));

    // Monthly chart data
    const monthly = await getMonthlyData();
    setMonthlyData(monthly);

    // Category data
    const catData = await getCategoryRevenue(startDate, endDate);
    setCategoryData(catData);

    setLoading(false);
  }

  function getDateRange(period: string): { startDate: string; endDate: string | null } {
    const now = new Date();
    const today = now.toISOString().split('T')[0];

    switch (period) {
      case 'today':
        return { startDate: today, endDate: today };
      case 'this_week':
        const weekStart = new Date(now.setDate(now.getDate() - now.getDay())).toISOString().split('T')[0];
        return { startDate: weekStart, endDate: today };
      case 'this_month':
        const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
        return { startDate: monthStart, endDate: null };
      case 'this_year':
        const yearStart = new Date(now.getFullYear(), 0, 1).toISOString().split('T')[0];
        return { startDate: yearStart, endDate: null };
      default:
        return { startDate: today, endDate: null };
    }
  }

  async function getMonthlyData() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    const result: { month: string; sales: number; purchases: number; profit: number }[] = [];

    for (let i = 0; i < 6; i++) {
      const startDate = new Date(new Date().getFullYear(), i, 1).toISOString().split('T')[0];
      const endDate = new Date(new Date().getFullYear(), i + 1, 0).toISOString().split('T')[0];

      const [invRes, poRes] = await Promise.all([
        supabase.from('invoices').select('total_amount').gte('invoice_date', startDate).lt('invoice_date', endDate),
        supabase.from('purchase_orders').select('total_amount').gte('order_date', startDate).lt('order_date', endDate),
      ]);

      const sales = (invRes.data || []).reduce((s: number, inv: any) => s + Number(inv.total_amount), 0);
      const purchases = (poRes.data || []).reduce((s: number, po: any) => s + Number(po.total_amount), 0);

      result.push({ month: months[i], sales, purchases, profit: sales * 0.35 });
    }

    return result;
  }

  async function getCategoryRevenue(startDate: string, endDate: string | null) {
    const { data } = await supabase
      .from('invoice_items')
      .select('subtotal, product:products(category:categories(name))')
      .gte('created_at', startDate)
      .lte('created_at', endDate || undefined);

    const catTotals: Record<string, number> = {};
    (data || []).forEach((item: any) => {
      const catName = item.product?.category?.name || 'Others';
      catTotals[catName] = (catTotals[catName] || 0) + Number(item.subtotal);
    });

    return Object.entries(catTotals)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 6)
      .map(([name, revenue], i) => ({ name, revenue, color: COLORS[i] }));
  }

  function exportToCSV() {
    let csv = '';
    let filename = '';

    switch (activeTab) {
      case 'sales':
        csv = 'Month,Sales,Purchases,Profit\n' + monthlyData.map(m => `${m.month},${m.sales},${m.purchases},${m.profit}`).join('\n');
        filename = 'sales_report.csv';
        break;
      case 'inventory':
        csv = 'Product,Units Sold,Revenue\n' + topProducts.map(p => `"${p.name}",${p.sales},${p.revenue}`).join('\n');
        filename = 'inventory_report.csv';
        break;
      case 'customers':
        csv = 'Customer,Revenue\n' + topCustomers.map(c => `"${c.name}",${c.revenue}`).join('\n');
        filename = 'customers_report.csv';
        break;
      default:
        csv = 'Month,Sales,Purchases,Profit\n' + monthlyData.map(m => `${m.month},${m.sales},${m.purchases},${m.profit}`).join('\n');
        filename = 'overview_report.csv';
    }

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  }

  const tabs = [
    { id: 'overview', label: 'Overview', icon: BarChart3 },
    { id: 'sales', label: 'Sales', icon: TrendingUp },
    { id: 'inventory', label: 'Inventory', icon: Package },
    { id: 'customers', label: 'Customers', icon: Users },
    { id: 'pl', label: 'P&L', icon: FileSpreadsheet },
  ];

  return (
    <div className="space-y-5 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Reports & Analytics</h1>
          <p className="text-muted-foreground text-sm mt-0.5">Business intelligence and performance reports</p>
        </div>
        <div className="flex items-center gap-2">
          <select value={period} onChange={e => setPeriod(e.target.value)} className="border border-border rounded-lg px-3 py-2 text-sm focus:outline-none">
            <option value="today">Today</option>
            <option value="this_week">This Week</option>
            <option value="this_month">This Month</option>
            <option value="this_year">This Year</option>
          </select>
          <button onClick={exportToCSV} className="flex items-center gap-2 border border-border px-4 py-2 rounded-lg text-sm hover:bg-muted transition">
            <Download className="w-4 h-4" />Export CSV
          </button>
        </div>
      </div>

      <div className="flex gap-1 bg-muted/50 p-1 rounded-xl w-fit">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as ReportTab)}
            className={`flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium transition ${activeTab === tab.id ? 'bg-white text-foreground shadow-sm' : 'text-muted-foreground hover:text-foreground'}`}
          >
            <tab.icon className="w-4 h-4" />
            {tab.label}
          </button>
        ))}
      </div>

      {/* KPI Summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="stat-card">
          <p className="text-xs text-muted-foreground">Total Revenue</p>
          <p className="text-xl font-bold text-foreground mt-1">{formatCurrency(stats.totalRevenue)}</p>
          <p className="text-xs text-green-600 font-medium mt-0.5">{stats.totalOrders} orders</p>
        </div>
        <div className="stat-card">
          <p className="text-xs text-muted-foreground">Total Purchases</p>
          <p className="text-xl font-bold text-foreground mt-1">{formatCurrency(stats.totalPurchases)}</p>
        </div>
        <div className="stat-card">
          <p className="text-xs text-muted-foreground">Gross Profit</p>
          <p className="text-xl font-bold text-green-600 mt-1">{formatCurrency(stats.grossProfit)}</p>
          <p className="text-xs text-muted-foreground mt-0.5">{stats.totalRevenue > 0 ? ((stats.grossProfit / stats.totalRevenue) * 100).toFixed(1) : 0}% margin</p>
        </div>
        <div className="stat-card">
          <p className="text-xs text-muted-foreground">Net Profit (Est.)</p>
          <p className="text-xl font-bold text-green-600 mt-1">{formatCurrency(stats.netProfit)}</p>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
        </div>
      ) : (
        <>
          {activeTab === 'overview' && (
            <>
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                <div className="bg-white rounded-xl border border-border p-5 shadow-sm">
                  <h3 className="text-sm font-semibold text-foreground mb-4">Sales vs Purchases vs Profit</h3>
                  <ResponsiveContainer width="100%" height={220}>
                    <BarChart data={monthlyData} barSize={14} barGap={2}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                      <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
                      <YAxis tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} tickFormatter={v => `৳${(v/100000).toFixed(0)}L`} />
                      <Tooltip formatter={(v: number) => [formatCurrency(v), '']} contentStyle={{ fontSize: 11, borderRadius: 8 }} />
                      <Legend wrapperStyle={{ fontSize: 11 }} />
                      <Bar dataKey="sales" fill="#3b82f6" radius={[3, 3, 0, 0]} name="Sales" />
                      <Bar dataKey="purchases" fill="#f59e0b" radius={[3, 3, 0, 0]} name="Purchases" />
                      <Bar dataKey="profit" fill="#10b981" radius={[3, 3, 0, 0]} name="Profit" />
                    </BarChart>
                  </ResponsiveContainer>
                </div>

                <div className="bg-white rounded-xl border border-border p-5 shadow-sm">
                  <h3 className="text-sm font-semibold text-foreground mb-4">Revenue by Category</h3>
                  {categoryData.length > 0 ? (
                    <div className="flex items-center gap-4">
                      <ResponsiveContainer width={160} height={160}>
                        <PieChart>
                          <Pie data={categoryData} cx="50%" cy="50%" innerRadius={45} outerRadius={70} paddingAngle={2} dataKey="revenue">
                            {categoryData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
                          </Pie>
                          <Tooltip formatter={(v: number) => [formatCurrency(v), '']} contentStyle={{ fontSize: 11, borderRadius: 8 }} />
                        </PieChart>
                      </ResponsiveContainer>
                      <div className="flex-1 space-y-2">
                        {categoryData.map(cat => (
                          <div key={cat.name} className="flex items-center justify-between gap-2">
                            <div className="flex items-center gap-1.5">
                              <div className="w-2 h-2 rounded-full" style={{ backgroundColor: cat.color }} />
                              <span className="text-[11px] text-muted-foreground truncate">{cat.name}</span>
                            </div>
                            <span className="text-[11px] font-semibold text-foreground">{formatCurrency(cat.revenue)}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  ) : (
                    <div className="text-center py-8 text-muted-foreground">No category data available</div>
                  )}
                </div>
              </div>

              <div className="table-wrapper">
                <div className="px-4 py-3 border-b border-border flex items-center justify-between">
                  <h3 className="text-sm font-semibold text-foreground">Top Selling Products</h3>
                </div>
                <table className="w-full">
                  <thead><tr className="bg-muted/40 border-b border-border">
                    {['#', 'Product', 'Units Sold', 'Revenue', 'Margin'].map(h => <th key={h} className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">{h}</th>)}
                  </tr></thead>
                  <tbody className="divide-y divide-border">
                    {topProducts.length > 0 ? topProducts.map((p, i) => (
                      <tr key={i} className="hover:bg-muted/30 transition-colors">
                        <td className="px-4 py-3 text-sm text-muted-foreground">{i + 1}</td>
                        <td className="px-4 py-3 text-sm font-semibold text-foreground">{p.name}</td>
                        <td className="px-4 py-3 text-sm text-foreground">{p.sales}</td>
                        <td className="px-4 py-3 text-sm font-semibold text-foreground">{formatCurrency(p.revenue)}</td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <div className="flex-1 h-1.5 bg-muted rounded-full max-w-[80px]">
                              <div className="h-full bg-blue-500 rounded-full" style={{ width: `${Math.min(p.revenue / stats.totalRevenue * 100 * 5, 80)}%` }} />
                            </div>
                            <span className="text-xs text-muted-foreground">{((p.revenue / (stats.totalRevenue || 1)) * 100).toFixed(1)}%</span>
                          </div>
                        </td>
                      </tr>
                    )) : (
                      <tr><td colSpan={5} className="px-4 py-8 text-center text-muted-foreground">No product sales data</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </>
          )}

          {activeTab === 'sales' && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <div className="bg-white rounded-xl border border-border p-5 shadow-sm">
                <h3 className="text-sm font-semibold text-foreground mb-4">Monthly Sales Trend</h3>
                <ResponsiveContainer width="100%" height={280}>
                  <BarChart data={monthlyData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                    <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} tickFormatter={v => `৳${(v/100000).toFixed(0)}L`} />
                    <Tooltip formatter={(v: number) => [formatCurrency(v), '']} contentStyle={{ fontSize: 11, borderRadius: 8 }} />
                    <Bar dataKey="sales" fill="#3b82f6" radius={[4, 4, 0, 0]} name="Sales" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
              <div className="bg-white rounded-xl border border-border p-5 shadow-sm">
                <h3 className="text-sm font-semibold text-foreground mb-4">Monthly Profit</h3>
                <ResponsiveContainer width="100%" height={280}>
                  <BarChart data={monthlyData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                    <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 11, fill: '#94a3b8' }} axisLine={false} tickLine={false} tickFormatter={v => `৳${(v/100000).toFixed(0)}L`} />
                    <Tooltip formatter={(v: number) => [formatCurrency(v), '']} contentStyle={{ fontSize: 11, borderRadius: 8 }} />
                    <Bar dataKey="profit" fill="#10b981" radius={[4, 4, 0, 0]} name="Profit" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}

          {activeTab === 'inventory' && (
            <div className="table-wrapper">
              <div className="px-4 py-3 border-b border-border">
                <h3 className="text-sm font-semibold text-foreground">Top Selling Products</h3>
              </div>
              <table className="w-full">
                <thead><tr className="bg-muted/40 border-b border-border">
                  {['#', 'Product', 'Units Sold', 'Revenue', 'Margin'].map(h => <th key={h} className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">{h}</th>)}
                </tr></thead>
                <tbody className="divide-y divide-border">
                  {topProducts.map((p, i) => (
                    <tr key={i} className="hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3 text-sm text-muted-foreground">{i + 1}</td>
                      <td className="px-4 py-3 text-sm font-semibold text-foreground">{p.name}</td>
                      <td className="px-4 py-3 text-sm text-foreground">{p.sales}</td>
                      <td className="px-4 py-3 text-sm font-semibold text-foreground">{formatCurrency(p.revenue)}</td>
                      <td className="px-4 py-3">
                        <span className="text-xs text-muted-foreground">{((p.revenue / (stats.totalRevenue || 1)) * 100).toFixed(1)}%</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {activeTab === 'customers' && (
            <div className="table-wrapper">
              <div className="px-4 py-3 border-b border-border">
                <h3 className="text-sm font-semibold text-foreground">Top Customers by Revenue</h3>
              </div>
              <table className="w-full">
                <thead><tr className="bg-muted/40 border-b border-border">
                  {['#', 'Customer', 'Total Purchases'].map(h => <th key={h} className="text-left text-xs font-semibold text-muted-foreground px-4 py-3">{h}</th>)}
                </tr></thead>
                <tbody className="divide-y divide-border">
                  {topCustomers.map((c, i) => (
                    <tr key={i} className="hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3 text-sm text-muted-foreground">{i + 1}</td>
                      <td className="px-4 py-3 text-sm font-semibold text-foreground">{c.name}</td>
                      <td className="px-4 py-3 text-sm font-semibold text-foreground">{formatCurrency(c.revenue)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {activeTab === 'pl' && (
            <div className="bg-white rounded-xl border border-border p-6 shadow-sm">
              <h3 className="text-sm font-semibold text-foreground mb-6">Profit & Loss Statement</h3>
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4 border-b border-border pb-4">
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">Gross Revenue</p>
                    <p className="text-2xl font-bold text-green-600">{formatCurrency(stats.totalRevenue)}</p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">Cost of Goods Sold</p>
                    <p className="text-2xl font-bold text-red-600">{formatCurrency(stats.totalPurchases)}</p>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4 border-b border-border pb-4">
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">Gross Profit</p>
                    <p className="text-xl font-bold text-blue-600">{formatCurrency(stats.grossProfit)}</p>
                    <p className="text-xs text-muted-foreground">{((stats.grossProfit / (stats.totalRevenue || 1)) * 100).toFixed(1)}% margin</p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground mb-1">Operating Expenses (Est.)</p>
                    <p className="text-xl font-bold text-red-600">{formatCurrency(stats.grossProfit * 0.23)}</p>
                    <p className="text-xs text-muted-foreground">23% of gross profit</p>
                  </div>
                </div>
                <div>
                  <p className="text-xs text-muted-foreground mb-1">Net Profit</p>
                  <p className="text-3xl font-bold text-green-600">{formatCurrency(stats.netProfit)}</p>
                  <p className="text-xs text-muted-foreground">{((stats.netProfit / (stats.totalRevenue || 1)) * 100).toFixed(1)}% net margin</p>
                </div>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
