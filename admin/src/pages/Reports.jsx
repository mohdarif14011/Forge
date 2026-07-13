import { useState, useEffect } from 'react';
import { getReports } from '../services/api';
import { AlertCircle } from 'lucide-react';

const Reports = () => {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchReports = async () => {
      setLoading(true);
      try {
        const data = await getReports();
        // Sort by timestamp descending
        data.sort((a, b) => {
          if (a.timestamp && b.timestamp) {
            return b.timestamp.seconds - a.timestamp.seconds;
          }
          return 0;
        });
        setReports(data);
      } catch (err) {
        console.error("Error fetching reports:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchReports();
  }, []);

  return (
    <div className="animate-fade-in">
      <div className="page-header">
        <h1 className="page-title">Issue Reports</h1>
      </div>

      <div className="card">
        <div className="table-wrapper" style={{ border: 'none', boxShadow: 'none' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Question ID</th>
                <th>Issue</th>
                <th>Details</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="4" style={{ textAlign: 'center', padding: '2rem' }}>
                    Loading reports...
                  </td>
                </tr>
              ) : reports.length === 0 ? (
                <tr>
                  <td colSpan="4" style={{ textAlign: 'center', padding: '2rem' }}>
                    No reports found.
                  </td>
                </tr>
              ) : (
                reports.map(report => (
                  <tr key={report.id}>
                    <td>
                      {report.timestamp
                        ? new Date(report.timestamp.seconds * 1000).toLocaleString()
                        : 'Unknown Date'}
                    </td>
                    <td style={{ fontFamily: 'monospace', fontSize: '0.85rem' }}>
                      {report.questionId}
                    </td>
                    <td>
                      <span style={{ 
                        display: 'inline-flex', 
                        alignItems: 'center', 
                        gap: '0.25rem',
                        padding: '0.25rem 0.5rem',
                        borderRadius: '4px',
                        backgroundColor: 'var(--color-danger-light)',
                        color: 'var(--color-danger)',
                        fontSize: '0.85rem',
                        fontWeight: 600
                      }}>
                        <AlertCircle size={14} /> {report.issue}
                      </span>
                    </td>
                    <td>{report.details || '-'}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default Reports;
