import { useState, useEffect } from 'react';
import { getDashboardStats, exportDonationsUrl } from '../services/api';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    setLoading(true);
    try {
      const res = await getDashboardStats();
      setStats(res.data);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to load dashboard data.');
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div style={{ padding: '40px', textAlign: 'center' }}>Loading Administrative Insights...</div>;
  if (error) return <div className="error-box" style={{ margin: '40px' }}>{error}</div>;

  return (
    <div className="fade-in">
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '16px', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div className="page-header" style={{ marginBottom: 0 }}>
          <h2>Community Overview Dashboard</h2>
          <p>Real-time financial performance and donor engagement metrics.</p>
        </div>
        <a 
          href={exportDonationsUrl()} 
          className="btn-success" 
          style={{ width: 'auto', padding: '12px 24px', textDecoration: 'none' }}
        >
          📥 Download Full Donation CSV
        </a>
      </div>

      {/* Top Level Summary Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 220px), 1fr))', gap: '20px', marginBottom: '32px' }}>
        <div className="card" style={{ textAlign: 'center', borderTop: '4px solid #4f46e5' }}>
          <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '8px', textTransform: 'uppercase', fontWeight: 600 }}>Total Collected</div>
          <div style={{ fontSize: '28px', fontWeight: 700, color: '#4f46e5' }}>₹{stats.totalAmount.toLocaleString('en-IN')}</div>
        </div>
        <div className="card" style={{ textAlign: 'center', borderTop: '4px solid #10b981' }}>
          <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '8px', textTransform: 'uppercase', fontWeight: 600 }}>Total Registrations</div>
          <div style={{ fontSize: '28px', fontWeight: 700, color: '#10b981' }}>{stats.totalDonorsRegistered}</div>
        </div>
        <div className="card" style={{ textAlign: 'center', borderTop: '4px solid #f59e0b' }}>
          <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '8px', textTransform: 'uppercase', fontWeight: 600 }}>Active Donors</div>
          <div style={{ fontSize: '28px', fontWeight: 700, color: '#f59e0b' }}>{stats.totalDonorsDonated}</div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 350px), 1fr))', gap: '24px' }}>
        
        {/* Monthly Breakdown */}
        <div className="card" style={{ minWidth: 0 }}>
          <h3 style={{ marginBottom: '20px', fontSize: '16px' }}>📅 Monthly Performance</h3>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ textAlign: 'left', borderBottom: '1px solid var(--border)' }}>
                  <th style={{ padding: '12px', fontSize: '12px', color: 'var(--text-muted)' }}>Month</th>
                  <th style={{ padding: '12px', fontSize: '12px', color: 'var(--text-muted)' }}>Donations</th>
                  <th style={{ padding: '12px', fontSize: '12px', color: 'var(--text-muted)', textAlign: 'right' }}>Total Amount</th>
                </tr>
              </thead>
              <tbody>
                {stats.monthlyStats.map((ms, i) => (
                  <tr key={i} style={{ borderBottom: '1px solid var(--border)' }}>
                    <td style={{ padding: '12px', fontWeight: 500 }}>{ms.month}</td>
                    <td style={{ padding: '12px' }}>{ms.count} Donor(s)</td>
                    <td style={{ padding: '12px', textAlign: 'right', fontWeight: 600 }}>₹{ms.amount.toLocaleString('en-IN')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Visual Analytics */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', minWidth: 0 }}>
          
          {/* Payment Mode Bars */}
          <div className="card">
            <h3 style={{ marginBottom: '20px', fontSize: '16px' }}>💳 Payment Mode Stats</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {stats.paymentModes.map((pm, i) => {
                const percentage = (pm.amount / stats.totalAmount) * 100;
                return (
                  <div key={i}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px', fontSize: '13px' }}>
                      <span style={{ fontWeight: 500 }}>{pm.name}</span>
                      <span style={{ color: 'var(--text-muted)' }}>₹{pm.amount.toLocaleString('en-IN')}</span>
                    </div>
                    <div style={{ width: '100%', height: '8px', background: '#f1f5f9', borderRadius: '4px', overflow: 'hidden' }}>
                      <div style={{ width: `${percentage}%`, height: '100%', background: '#4f46e5', borderRadius: '4px' }} />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Purpose Bars */}
          <div className="card">
            <h3 style={{ marginBottom: '20px', fontSize: '16px' }}>🏗 Campaign / Purpose Stats</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {stats.purposes.map((p, i) => {
                const percentage = (p.amount / stats.totalAmount) * 100;
                return (
                  <div key={i}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px', fontSize: '13px' }}>
                      <span style={{ fontWeight: 500 }}>{p.name}</span>
                      <span style={{ color: 'var(--text-muted)' }}>₹{p.amount.toLocaleString('en-IN')}</span>
                    </div>
                    <div style={{ width: '100%', height: '8px', background: '#f1f5f9', borderRadius: '4px', overflow: 'hidden' }}>
                      <div style={{ width: `${percentage}%`, height: '100%', background: '#10b981', borderRadius: '4px' }} />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
