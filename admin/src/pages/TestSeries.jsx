import { useState, useEffect } from 'react';
import { Search, ChevronRight, Edit, Trash2, Plus, BarChart2, Check, ArrowLeft } from 'lucide-react';
import { getExams, getTestSeries } from '../services/api';
import { collection, addDoc, deleteDoc, doc, getDocs, query, where, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';

const TestSeries = () => {
  const [view, setView] = useState('exams'); // exams | tests | performance | create
  const [selectedExam, setSelectedExam] = useState(null);
  const [selectedTest, setSelectedTest] = useState(null);
  
  const [exams, setExams] = useState([]);
  const [tests, setTests] = useState([]);
  const [loading, setLoading] = useState(false);

  // Form State
  const [testName, setTestName] = useState('');
  const [formExamId, setFormExamId] = useState('');
  const [durationVal, setDurationVal] = useState(180);
  const [formSubject, setFormSubject] = useState('');
  const [formChapters, setFormChapters] = useState([]);
  const [availableQuestions, setAvailableQuestions] = useState([]);
  const [selectedQuestions, setSelectedQuestions] = useState([]);
  const [fetchingQuestions, setFetchingQuestions] = useState(false);
  const [savingTest, setSavingTest] = useState(false);
  const [questionSearch, setQuestionSearch] = useState('');

  // Performance State
  const [performanceResults, setPerformanceResults] = useState([]);
  const [loadingPerformance, setLoadingPerformance] = useState(false);

  useEffect(() => {
    const fetchExams = async () => {
      const data = await getExams();
      setExams(data);
    };
    fetchExams();
  }, []);

  const handleExamClick = async (exam) => { 
    setSelectedExam(exam); 
    setView('tests');
    setLoading(true);
    try {
      const data = await getTestSeries();
      setTests(data.filter(t => t.examId === exam.id));
    } catch (error) {
      console.error("Error fetching test series:", error);
    } finally {
      setLoading(false);
    }
  };

  const handlePerformanceClick = async (test) => {
    setSelectedTest(test);
    setView('performance');
    setLoadingPerformance(true);
    try {
      const q = query(
        collection(db, 'test_results'),
        where('testSeriesId', '==', test.id)
      );
      const snapshot = await getDocs(q);
      const results = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      // Sort by score descending
      results.sort((a, b) => (b.score || 0) - (a.score || 0));
      setPerformanceResults(results);
    } catch (error) {
      console.error("Error loading performance:", error);
    } finally {
      setLoadingPerformance(false);
    }
  };

  const handleBack = (toView) => { 
    setView(toView); 
  };

  const handleCreateClick = () => {
    setTestName('');
    setFormExamId(selectedExam ? selectedExam.id : '');
    setDurationVal(180);
    setFormSubject('');
    setFormChapters([]);
    setSelectedQuestions([]);
    setQuestionSearch('');
    setView('create');
  };

  // Fetch questions for form when formExamId changes
  useEffect(() => {
    if (!formExamId) {
      setAvailableQuestions([]);
      return;
    }
    const fetchQuestions = async () => {
      setFetchingQuestions(true);
      try {
        const q = query(collection(db, 'questions'), where('examId', '==', formExamId));
        const snapshot = await getDocs(q);
        const questionsList = snapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
        setAvailableQuestions(questionsList);
      } catch (error) {
        console.error("Error fetching questions:", error);
      } finally {
        setFetchingQuestions(false);
      }
    };
    fetchQuestions();
  }, [formExamId]);

  const handleChapterToggle = (chapName) => {
    if (formChapters.includes(chapName)) {
      setFormChapters(formChapters.filter(c => c !== chapName));
    } else {
      setFormChapters([...formChapters, chapName]);
    }
  };

  const handleQuestionToggle = (qId) => {
    if (selectedQuestions.includes(qId)) {
      setSelectedQuestions(selectedQuestions.filter(id => id !== qId));
    } else {
      setSelectedQuestions([...selectedQuestions, qId]);
    }
  };

  const handleSelectAllQuestions = (filteredQs) => {
    const filteredIds = filteredQs.map(q => q.id);
    const newSelected = [...new Set([...selectedQuestions, ...filteredIds])];
    setSelectedQuestions(newSelected);
  };

  const handleDeselectAllQuestions = (filteredQs) => {
    const filteredIds = filteredQs.map(q => q.id);
    setSelectedQuestions(selectedQuestions.filter(id => !filteredIds.includes(id)));
  };

  const handleDeleteTest = async (testId) => {
    if (window.confirm('Are you sure you want to delete this test series?')) {
      try {
        await deleteDoc(doc(db, 'testSeries', testId));
        setTests(tests.filter(t => t.id !== testId));
      } catch (error) {
        console.error("Error deleting test series:", error);
        alert('Failed to delete test series');
      }
    }
  };

  const handleSaveTest = async (e) => {
    e.preventDefault();
    if (!testName.trim() || !formExamId || selectedQuestions.length === 0) {
      alert('Please fill out all fields and select at least one question.');
      return;
    }

    setSavingTest(true);
    try {
      const selectedExamObj = exams.find(ex => ex.id === formExamId);
      const testData = {
        name: testName.trim(),
        examId: formExamId,
        examName: selectedExamObj ? selectedExamObj.name : 'Unknown Exam',
        time: parseInt(durationVal) || 180,
        subject: formSubject || 'Mixed',
        chapters: formChapters,
        questions: selectedQuestions,
        status: 'Active',
        totalStudents: 0,
        avgScore: 0,
        createdAt: serverTimestamp()
      };

      const docRef = await addDoc(collection(db, 'testSeries'), testData);
      
      // Update local tests state if the created test is for currently selected exam
      if (selectedExam && formExamId === selectedExam.id) {
        setTests([{ id: docRef.id, ...testData, totalStudents: 0, avgScore: 0 }, ...tests]);
      }

      alert('Test Series created successfully!');
      setView('tests');
    } catch (error) {
      console.error("Error saving test series:", error);
      alert('Failed to create test series');
    } finally {
      setSavingTest(false);
    }
  };

  // Get subjects for selected exam in form
  const getSelectedExamSubjects = () => {
    const exam = exams.find(e => e.id === formExamId);
    return exam ? exam.subjects || [] : [];
  };

  // Get chapters for selected subject in form
  const getSelectedSubjectChapters = () => {
    const subjects = getSelectedExamSubjects();
    const subject = subjects.find(s => s.name === formSubject);
    return subject ? subject.chapters || [] : [];
  };

  // Filter questions based on selections
  const getFilteredQuestions = () => {
    return availableQuestions.filter(q => {
      // Filter by subject
      if (formSubject && q.subject !== formSubject) return false;
      // Filter by chapters
      if (formChapters.length > 0 && !formChapters.includes(q.chapter)) return false;
      if (questionSearch.trim()) {
        const text = q.text || q.questionText || '';
        if (!text.toLowerCase().includes(questionSearch.toLowerCase())) return false;
      }
      return true;
    });
  };

  return (
    <div className="animate-fade-in" style={{ padding: '1rem' }}>
      <div className="page-header" style={{ marginBottom: '1rem' }}>
        <h1 className="page-title">Test Series Management</h1>
        {view === 'tests' && (
          <button className="btn-primary" onClick={handleCreateClick}>
            <Plus size={18} /> Create New Test
          </button>
        )}
      </div>

      {/* Breadcrumbs */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '2rem', color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
        <span style={{ cursor: 'pointer', color: view === 'exams' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('exams')}>Exams</span>
        {selectedExam && (
          <>
            <ChevronRight size={14} /> 
            <span style={{ cursor: 'pointer', color: view === 'tests' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('tests')}>{selectedExam.name}</span> 
          </>
        )}
        {selectedTest && view === 'performance' && (
          <>
            <ChevronRight size={14} /> 
            <span style={{ color: 'var(--color-text-main)', fontWeight: 500 }}>{selectedTest.name} Performance</span> 
          </>
        )}
        {view === 'create' && (
          <>
            <ChevronRight size={14} /> 
            <span style={{ color: 'var(--color-text-main)', fontWeight: 500 }}>Create New Test</span> 
          </>
        )}
      </div>

      {view === 'exams' && (
        <div>
          <div style={{ position: 'relative', maxWidth: '400px', marginBottom: '1.5rem' }}>
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

      {view === 'tests' && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
            <h2 style={{ margin: 0 }}>{selectedExam.name} Test Series</h2>
            <div style={{ position: 'relative' }}>
              <Search size={16} style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
              <input type="text" className="form-control" placeholder="Search tests..." style={{ paddingLeft: '2.25rem' }} />
            </div>
          </div>

          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Test Name</th>
                  <th>Status</th>
                  <th>Questions</th>
                  <th>Duration</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="5" style={{ textAlign: 'center', padding: '2rem' }}>Loading test series...</td></tr>
                ) : tests.length === 0 ? (
                  <tr><td colSpan="5" style={{ textAlign: 'center', padding: '2rem' }}>No tests found.</td></tr>
                ) : tests.map(test => (
                  <tr key={test.id}>
                    <td style={{ fontWeight: 500 }}>{test.name}</td>
                    <td>
                      <span className="badge badge-success">
                        {test.status || 'Active'}
                      </span>
                    </td>
                    <td>{test.questions?.length || 0} Qs</td>
                    <td>{test.time || 180} mins</td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem' }}>
                        <button className="btn-outline" onClick={() => handlePerformanceClick(test)} style={{ padding: '0.4rem', color: 'var(--color-success)', borderColor: 'var(--color-success-light)' }} title="View Performance">
                          <BarChart2 size={16} />
                        </button>
                        <button className="btn-outline" onClick={() => handleDeleteTest(test.id)} style={{ padding: '0.4rem', color: 'var(--color-danger)', borderColor: 'var(--color-danger-light)' }} title="Delete Test">
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

      {view === 'create' && (
        <div className="card animate-fade-in" style={{ padding: '2rem', maxWidth: '900px', margin: '0 auto' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2rem' }}>
            <button className="btn-icon" onClick={() => setView('tests')}>
              <ArrowLeft size={18} />
            </button>
            <h2 style={{ fontSize: '1.5rem', fontWeight: '600' }}>Create Test Series</h2>
          </div>

          <form onSubmit={handleSaveTest}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', marginBottom: '1.5rem' }}>
              <div className="form-group">
                <label className="form-label">Test Series Title</label>
                <input
                  type="text"
                  required
                  value={testName}
                  onChange={(e) => setTestName(e.target.value)}
                  placeholder="e.g. JEE Main Full Mock Test 1"
                  className="form-control"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Allotted Duration (Minutes)</label>
                <input
                  type="number"
                  required
                  min="1"
                  value={durationVal}
                  onChange={(e) => setDurationVal(e.target.value)}
                  placeholder="e.g. 180"
                  className="form-control"
                />
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', marginBottom: '1.5rem' }}>
              <div className="form-group">
                <label className="form-label">Target Exam</label>
                <select 
                  className="form-control" 
                  value={formExamId} 
                  onChange={(e) => {
                    setFormExamId(e.target.value);
                    setFormSubject('');
                    setFormChapters([]);
                  }}
                  required
                >
                  <option value="">Select Exam</option>
                  {exams.map(ex => (
                    <option key={ex.id} value={ex.id}>{ex.name}</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label className="form-label">Subject (Optional - Leave blank for mixed test)</label>
                <select 
                  className="form-control" 
                  value={formSubject} 
                  onChange={(e) => {
                    setFormSubject(e.target.value);
                    setFormChapters([]);
                  }}
                  disabled={!formExamId}
                >
                  <option value="">All Subjects (Mixed)</option>
                  {getSelectedExamSubjects().map((sub, idx) => (
                    <option key={idx} value={sub.name}>{sub.name}</option>
                  ))}
                </select>
              </div>
            </div>

            {formSubject && (
              <div className="form-group" style={{ marginBottom: '1.5rem' }}>
                <label className="form-label">Select Chapters (Optional - Leave empty to include all)</label>
                <div style={{ 
                  display: 'grid', 
                  gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', 
                  gap: '0.75rem', 
                  maxHeight: '150px', 
                  overflowY: 'auto',
                  border: '1px solid var(--color-border)',
                  borderRadius: 'var(--radius-md)',
                  padding: '1rem',
                  backgroundColor: 'var(--color-background)'
                }}>
                  {getSelectedSubjectChapters().map((chap, idx) => (
                    <label key={idx} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', cursor: 'pointer' }}>
                      <input 
                        type="checkbox" 
                        checked={formChapters.includes(chap)}
                        onChange={() => handleChapterToggle(chap)}
                      />
                      <span>{chap}</span>
                    </label>
                  ))}
                </div>
              </div>
            )}

            {/* Questions Selection list */}
            <div className="form-group" style={{ marginBottom: '2rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
                <label className="form-label" style={{ margin: 0 }}>
                  Select Questions ({selectedQuestions.length} Selected)
                </label>
                <div style={{ fontSize: '0.825rem', display: 'flex', gap: '1rem' }}>
                  <button type="button" style={{ color: 'var(--color-primary)', fontWeight: 500 }} onClick={() => handleSelectAllQuestions(getFilteredQuestions())}>Select All Filtered</button>
                  <button type="button" style={{ color: 'var(--color-danger)', fontWeight: 500 }} onClick={() => handleDeselectAllQuestions(getFilteredQuestions())}>Clear Filtered</button>
                </div>
              </div>

              <div style={{ position: 'relative', marginBottom: '1rem' }}>
                <Search size={16} style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-text-muted)' }} />
                <input 
                  type="text" 
                  className="form-control" 
                  placeholder="Search questions by text..." 
                  style={{ paddingLeft: '2.25rem', fontSize: '0.825rem' }} 
                  value={questionSearch}
                  onChange={(e) => setQuestionSearch(e.target.value)}
                  disabled={!formExamId}
                />
              </div>

              <div style={{ 
                border: '1px solid var(--color-border)', 
                borderRadius: 'var(--radius-md)', 
                maxHeight: '300px', 
                overflowY: 'auto',
                backgroundColor: 'var(--color-background)'
              }}>
                {fetchingQuestions ? (
                  <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--color-text-muted)' }}>Loading exam questions...</div>
                ) : !formExamId ? (
                  <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--color-text-muted)' }}>Please select a target exam first.</div>
                ) : getFilteredQuestions().length === 0 ? (
                  <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--color-text-muted)' }}>No questions match your filters.</div>
                ) : (
                  getFilteredQuestions().map((q, idx) => {
                    const isChecked = selectedQuestions.includes(q.id);
                    return (
                      <div 
                        key={q.id} 
                        onClick={() => handleQuestionToggle(q.id)}
                        style={{ 
                          display: 'flex', 
                          alignItems: 'flex-start', 
                          gap: '1rem', 
                          padding: '1rem', 
                          borderBottom: '1px solid var(--color-border-light)',
                          cursor: 'pointer',
                          backgroundColor: isChecked ? 'var(--color-primary-light)' : 'transparent',
                          transition: 'background-color 150ms'
                        }}
                      >
                        <div style={{ 
                          width: '20px', 
                          height: '20px', 
                          borderRadius: '4px', 
                          border: '2px solid ' + (isChecked ? 'var(--color-primary)' : 'var(--color-text-muted)'),
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          backgroundColor: isChecked ? 'var(--color-primary)' : 'transparent',
                          color: 'white',
                          marginTop: '2px',
                          flexShrink: 0
                        }}>
                          {isChecked && <Check size={14} strokeWidth={3} />}
                        </div>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontSize: '0.875rem', fontWeight: 500, color: 'var(--color-secondary)', lineHeight: '1.4', marginBottom: '0.5rem' }}>
                            {q.text || q.questionText || `[Question ID: ${q.id}]`}
                          </div>
                          <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                            <span className="badge badge-primary" style={{ fontSize: '0.7rem' }}>{q.subject}</span>
                            <span className="badge badge-warning" style={{ fontSize: '0.7rem' }}>{q.chapter}</span>
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>

            <div style={{ display: 'flex', gap: '1rem', justifyContent: 'flex-end', borderTop: '1px solid var(--color-border-light)', paddingTop: '1.5rem' }}>
              <button type="button" className="btn-outline" onClick={() => setView('tests')}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={savingTest}>
                {savingTest ? 'Saving...' : 'Save Test Series'}
              </button>
            </div>
          </form>
        </div>
      )}

      {view === 'performance' && (
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '2rem' }}>
            <button className="btn-icon" onClick={() => setView('tests')}>
              <ArrowLeft size={18} />
            </button>
            <h2 style={{ fontSize: '1.5rem', fontWeight: '600' }}>Performance Overview: {selectedTest.name}</h2>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
            <div className="card">
              <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Total Students Appeared</div>
              <div style={{ fontSize: '1.875rem', fontWeight: 700, color: 'var(--color-primary)' }}>
                {performanceResults.length}
              </div>
            </div>
            <div className="card">
              <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Average Score</div>
              <div style={{ fontSize: '1.875rem', fontWeight: 700, color: 'var(--color-success)' }}>
                {performanceResults.length > 0 
                  ? (performanceResults.reduce((acc, curr) => acc + (curr.score || 0), 0) / performanceResults.length).toFixed(1)
                  : 'N/A'
                }
              </div>
            </div>
            <div className="card">
              <div style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem', marginBottom: '0.5rem' }}>Highest Score</div>
              <div style={{ fontSize: '1.875rem', fontWeight: 700, color: 'var(--color-warning)' }}>
                {performanceResults.length > 0 
                  ? Math.max(...performanceResults.map(r => r.score || 0))
                  : 'N/A'
                }
              </div>
            </div>
          </div>
          
          <div className="card">
            <h3 style={{ marginBottom: '1rem' }}>Rankings List (Leaderboard)</h3>
            <div className="table-wrapper">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Rank</th>
                    <th>Student Name</th>
                    <th>Score</th>
                    <th>Accuracy</th>
                  </tr>
                </thead>
                <tbody>
                  {loadingPerformance ? (
                    <tr><td colSpan="4" style={{ textAlign: 'center', padding: '2rem' }}>Loading leaderboard...</td></tr>
                  ) : performanceResults.length === 0 ? (
                    <tr>
                      <td colSpan="4" style={{ textAlign: 'center', padding: '2rem', color: 'var(--color-text-muted)' }}>
                        No student performance data available yet.
                      </td>
                    </tr>
                  ) : performanceResults.map((result, idx) => {
                    const totalAnswered = (result.correct || 0) + (result.incorrect || 0);
                    const accuracy = totalAnswered > 0 ? ((result.correct || 0) / totalAnswered) * 100 : 0;
                    return (
                      <tr key={result.id}>
                        <td style={{ fontWeight: 700 }}>#{idx + 1}</td>
                        <td>{result.userName || 'Student'}</td>
                        <td style={{ fontWeight: 600, color: 'var(--color-primary)' }}>{result.score} pts</td>
                        <td style={{ color: 'var(--color-success)' }}>{accuracy.toFixed(0)}%</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TestSeries;
