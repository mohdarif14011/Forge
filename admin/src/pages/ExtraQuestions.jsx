import { useState, useEffect } from 'react';
import { Search, ChevronRight, Edit, Trash2, Plus } from 'lucide-react';
import { getExams, getQuestions } from '../services/api';

const ExtraQuestions = () => {
  const [view, setView] = useState('exams');
  const [selectedExam, setSelectedExam] = useState(null);
  const [selectedSubject, setSelectedSubject] = useState(null);
  const [selectedChapter, setSelectedChapter] = useState(null);

  const [exams, setExams] = useState([]);
  const [questions, setQuestions] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const fetchExams = async () => {
      const data = await getExams();
      setExams(data);
    };
    fetchExams();
  }, []);

  const handleExamClick = (exam) => { setSelectedExam(exam); setView('subjects'); };
  const handleSubjectClick = (sub) => { setSelectedSubject(sub); setView('chapters'); };
  
  const handleChapterClick = async (chap) => { 
    setSelectedChapter(chap); 
    setView('questions'); 
    setLoading(true);
    const data = await getQuestions('extra');
    setQuestions(data);
    setLoading(false);
  };

  const handleBack = (toView) => { setView(toView); };

  return (
    <div className="animate-fade-in">
      <div className="page-header" style={{ marginBottom: '1rem' }}>
        <h1 className="page-title">Extra Questions Management</h1>
        {view === 'questions' && (
          <button className="btn-primary">
            <Plus size={18} /> Add New Question
          </button>
        )}
      </div>

      {/* Breadcrumbs */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '2rem', color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
        <span style={{ cursor: 'pointer', color: view === 'exams' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('exams')}>Exams</span>
        {selectedExam && <> <ChevronRight size={14} /> <span style={{ cursor: 'pointer', color: view === 'subjects' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('subjects')}>{selectedExam.name}</span> </>}
        {selectedSubject && view !== 'exams' && view !== 'subjects' && <> <ChevronRight size={14} /> <span style={{ cursor: 'pointer', color: view === 'chapters' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('chapters')}>{selectedSubject.name}</span> </>}
        {selectedChapter && view === 'questions' && <> <ChevronRight size={14} /> <span style={{ color: 'var(--color-text-main)', fontWeight: 500 }}>{selectedChapter.name}</span> </>}
      </div>

      {view === 'exams' && (
        <div>
          <div style={{ position: 'relative', maxWidth: '400px' }}>
            <Search size={20} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
            <input type="text" className="form-control" placeholder="Search Exams..." style={{ paddingLeft: '2.75rem' }} />
          </div>
          <div className="exam-grid">
            {exams.map(exam => (
              <div key={exam.id} className="card exam-card" onClick={() => handleExamClick(exam)}>
                <div className="exam-logo">{exam.logo || exam.name.substring(0,2).toUpperCase()}</div>
                <h3 style={{ margin: 0, fontSize: '1.125rem' }}>{exam.name}</h3>
              </div>
            ))}
          </div>
        </div>
      )}

      {view === 'subjects' && selectedExam && (
        <div>
          <h2 style={{ marginBottom: '1.5rem' }}>Select Subject for {selectedExam.name}</h2>
          <div className="exam-grid">
            {(selectedExam.subjects || []).length === 0 ? (
              <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--color-text-muted)' }}>No subjects found for this exam.</div>
            ) : selectedExam.subjects.map((sub, i) => (
              <div key={i} className="card exam-card" style={{ padding: '1.5rem' }} onClick={() => handleSubjectClick(sub)}>
                <h3 style={{ margin: 0, fontSize: '1.125rem' }}>{sub.name}</h3>
              </div>
            ))}
          </div>
        </div>
      )}

      {view === 'chapters' && selectedSubject && (
        <div>
          <h2 style={{ marginBottom: '1.5rem' }}>{selectedSubject.name} Chapters</h2>
          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Chapter Name</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {(selectedSubject.chapters || []).length === 0 ? (
                  <tr><td colSpan="2" style={{ textAlign: 'center', padding: '2rem' }}>No chapters configured.</td></tr>
                ) : selectedSubject.chapters.map((chap, i) => (
                  <tr key={i}>
                    <td style={{ fontWeight: 500 }}>{chap}</td>
                    <td>
                      <button className="btn-outline" onClick={() => handleChapterClick({ name: chap })} style={{ padding: '0.25rem 0.75rem', fontSize: '0.875rem' }}>
                        View Questions
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {view === 'questions' && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
            <h2 style={{ margin: 0 }}>Questions for {selectedChapter.name}</h2>
            <div style={{ position: 'relative' }}>
              <Search size={16} style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
              <input type="text" className="form-control" placeholder="Search questions..." style={{ paddingLeft: '2.25rem' }} />
            </div>
          </div>

          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '50px' }}>ID</th>
                  <th>Question Summary</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="3" style={{ textAlign: 'center', padding: '2rem' }}>Loading questions from Firebase...</td></tr>
                ) : questions.length === 0 ? (
                  <tr><td colSpan="3" style={{ textAlign: 'center', padding: '2rem' }}>No questions found.</td></tr>
                ) : questions.map(q => (
                  <tr key={q.id}>
                    <td>#{q.id.toString().substring(0,4)}</td>
                    <td>
                      <div style={{ maxWidth: '600px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {q.text}
                      </div>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem' }}>
                        <button className="btn-outline" style={{ padding: '0.4rem', color: 'var(--color-primary)' }} title="Edit">
                          <Edit size={16} />
                        </button>
                        <button className="btn-outline" style={{ padding: '0.4rem', color: 'var(--color-danger)', borderColor: 'var(--color-danger-light)' }} title="Delete">
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default ExtraQuestions;
