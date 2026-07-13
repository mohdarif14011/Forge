import { useState, useEffect } from 'react';
import { Search, ChevronRight, Upload, Trash2, Book } from 'lucide-react';
import { getExams } from '../services/api';

const Books = () => {
  const [view, setView] = useState('exams'); // exams | books
  const [selectedExam, setSelectedExam] = useState(null);

  const [exams, setExams] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const fetchExamsData = async () => {
      setLoading(true);
      const data = await getExams();
      setExams(data);
      setLoading(false);
    };
    fetchExamsData();
  }, []);

  const handleExamClick = (exam) => { setSelectedExam(exam); setView('books'); };
  const handleBack = () => { setView('exams'); };

  return (
    <div className="animate-fade-in">
      <div className="page-header" style={{ marginBottom: '1rem' }}>
        <h1 className="page-title">Books Management</h1>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '2rem', color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
        <span style={{ cursor: 'pointer', color: view === 'exams' ? 'var(--color-primary)' : 'inherit' }} onClick={handleBack}>Exams</span>
        {selectedExam && <> <ChevronRight size={14} /> <span style={{ color: 'var(--color-text-main)', fontWeight: 500 }}>{selectedExam.name} Books</span> </>}
      </div>

      {view === 'exams' && (
        <div className="exam-grid">
          {loading ? (
            <div style={{ padding: '2rem', textAlign: 'center', gridColumn: '1 / -1' }}>Loading...</div>
          ) : exams.length === 0 ? (
            <div style={{ padding: '2rem', textAlign: 'center', gridColumn: '1 / -1', color: 'var(--color-text-muted)' }}>No exams found.</div>
          ) : exams.map(exam => (
            <div key={exam.id} className="card exam-card" onClick={() => handleExamClick(exam)}>
              <div className="exam-logo">{exam.logo || exam.name.substring(0,2).toUpperCase()}</div>
              <h3 style={{ margin: 0, fontSize: '1.125rem' }}>{exam.name}</h3>
            </div>
          ))}
        </div>
      )}

      {view === 'books' && (
        <div>
          <div className="card" style={{ backgroundColor: 'var(--color-primary-light)', borderColor: 'var(--color-primary)', textAlign: 'center', padding: '2rem', borderStyle: 'dashed', marginBottom: '2rem' }}>
            <Upload size={32} color="var(--color-primary)" style={{ margin: '0 auto 1rem auto' }} />
            <h3 style={{ color: 'var(--color-primary)', marginBottom: '0.5rem' }}>Upload Book (PDF)</h3>
            <button className="btn-primary" style={{ marginTop: '1rem' }}>Browse Files</button>
          </div>

          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Book Title</th>
                  <th>Author</th>
                  <th>Upload Date</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td colSpan="4" style={{ textAlign: 'center', padding: '2rem', color: 'var(--color-text-muted)' }}>
                    No books uploaded yet.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default Books;
