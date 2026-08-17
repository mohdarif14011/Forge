import { useState, useEffect } from 'react';
import { Search, ChevronRight, Edit, Trash2, Plus, Filter, ChevronDown, ChevronUp, X, Loader2 } from 'lucide-react';
import { getExams, getQuestions, addQuestion, updateQuestion, deleteQuestion, uploadImage } from '../services/api';
import 'katex/dist/katex.min.css';
import katex from 'katex';

const Latex = ({ children }) => {
  if (typeof children !== 'string') return <>{children}</>;
  const parts = children.split('$');
  return (
    <>
      {parts.map((part, i) => {
        if (i % 2 === 1) {
          try {
            const html = katex.renderToString(part, { throwOnError: false, displayMode: false });
            return <span key={i} dangerouslySetInnerHTML={{ __html: html }} />;
          } catch (e) {
            return <span key={i} style={{ color: 'red' }}>${part}$</span>;
          }
        }
        return <span key={i}>{part}</span>;
      })}
    </>
  );
};

const PYQs = () => {
  const [view, setView] = useState('exams'); // exams | subjects | chapters | questions
  const [selectedExam, setSelectedExam] = useState(null);
  const [selectedSubject, setSelectedSubject] = useState(null);
  const [selectedChapter, setSelectedChapter] = useState(null);

  const [exams, setExams] = useState([]);
  const [questions, setQuestions] = useState([]);
  const [loading, setLoading] = useState(false);
  
  const [expandedYears, setExpandedYears] = useState({});

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  // Form State
  const [formData, setFormData] = useState({
    text: '',
    options: ['', '', '', ''],
    correctAnswer: '',
    explanation: '',
    year: '',
    date: '',
    shift: '',
    marks: 4,
    negativeMarks: -1,
    imageUrl: '',
    imageUrls: [],
    optionImages: [],
    solutionImageUrl: '',
    solutionImageUrls: []
  });

  useEffect(() => {
    const fetchExams = async () => {
      const data = await getExams();
      setExams(data);
    };
    fetchExams();
  }, []);

  const handleExamClick = (exam) => { setSelectedExam(exam); setView('subjects'); };
  const handleSubjectClick = (sub) => { setSelectedSubject(sub); setView('chapters'); };
  
  const fetchQuestions = async (exam = selectedExam, subject = selectedSubject, chapter = selectedChapter) => {
    if (!exam || !subject || !chapter) return;
    setLoading(true);
    // Note: To properly filter by chapter, we would modify getQuestions or filter locally. 
    // Assuming getQuestions fetches all PYQs and we filter by selectedChapter.name
    const data = await getQuestions('pyq');
    const filtered = data.filter(q => 
        q.examId === exam.id && 
        q.subject === subject.name && 
        q.chapter === chapter.name
    );
    setQuestions(filtered);
    setLoading(false);
  };

  const handleChapterClick = async (chap) => { 
    setSelectedChapter(chap); 
    setView('questions'); 
    await fetchQuestions(selectedExam, selectedSubject, chap);
  };

  const handleBack = (toView) => { setView(toView); };

  const toggleYear = (year) => {
    setExpandedYears(prev => ({ ...prev, [year]: !prev[year] }));
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this question?')) {
      await deleteQuestion(id);
      await fetchQuestions();
    }
  };

  const openModal = (q = null) => {
    if (q) {
      setEditingId(q.id);
      setFormData({
        text: q.text || '',
        options: q.options || ['', '', '', ''],
        correctAnswer: q.correctAnswer || '',
        explanation: q.explanation || '',
        year: q.year || '',
        date: q.date || '',
        shift: q.shift || '',
        marks: q.marks || 4,
        negativeMarks: q.negativeMarks || -1,
        imageUrl: q.imageUrl || '',
        imageUrls: q.imageUrls || (q.imageUrl ? [q.imageUrl] : []),
        optionImages: q.optionImages || [],
        solutionImageUrl: q.solutionImageUrl || '',
        solutionImageUrls: q.solutionImageUrls || (q.solutionImageUrl ? [q.solutionImageUrl] : [])
      });
    } else {
      setEditingId(null);
      setFormData({
        text: '',
        options: ['', '', '', ''],
        correctAnswer: '',
        explanation: '',
        year: new Date().getFullYear().toString(),
        date: '',
        shift: 'Morning Shift',
        marks: 4,
        negativeMarks: -1,
        imageUrl: '',
        imageUrls: [],
        optionImages: [],
        solutionImageUrl: '',
        solutionImageUrls: []
      });
    }
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setEditingId(null);
  };

  const handleImageUpload = async (e, optIndex = null) => {
    const files = Array.from(e.target.files);
    if (files.length === 0) return;
    try {
      if (optIndex === null || optIndex === 'explanation') {
        const urls = await Promise.all(files.map(f => uploadImage(f)));
        if (optIndex === null) {
          setFormData(prev => ({ 
            ...prev, 
            imageUrls: [...(prev.imageUrls || []), ...urls],
          }));
        } else if (optIndex === 'explanation') {
          setFormData(prev => ({ 
            ...prev, 
            solutionImageUrls: [...(prev.solutionImageUrls || []), ...urls],
          }));
        }
      } else {
        const url = await uploadImage(files[0]);
        const optionImages = [...(formData.optionImages || ["","","",""])];
        optionImages[optIndex] = url;
        setFormData(prev => ({ ...prev, optionImages }));
      }
    } catch (err) {
      console.error(err);
      alert("Failed to upload image(s): " + err.message);
    } finally {
      e.target.value = null;
    }
  };

  const handleSave = async () => {
    setIsSubmitting(true);
    try {
      const payload = {
        ...formData,
        imageUrl: formData.imageUrls && formData.imageUrls.length > 0 ? formData.imageUrls[0] : (formData.imageUrl || ''),
        solutionImageUrl: formData.solutionImageUrls && formData.solutionImageUrls.length > 0 ? formData.solutionImageUrls[0] : (formData.solutionImageUrl || ''),
        type: 'pyq',
        examId: selectedExam.id,
        examName: selectedExam.name,
        subject: selectedSubject.name,
        chapter: selectedChapter.name,
      };

      if (editingId) {
        await updateQuestion(editingId, payload);
      } else {
        await addQuestion(payload);
      }
      
      closeModal();
      await fetchQuestions();
    } catch (e) {
      alert("Error saving: " + e.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const questionsByYear = questions.reduce((acc, q) => {
    const year = q.year || 'Unknown';
    if (!acc[year]) acc[year] = [];
    acc[year].push(q);
    return acc;
  }, {});

  return (
    <div className="animate-fade-in" style={{ position: 'relative' }}>
      <div className="page-header" style={{ marginBottom: '1rem' }}>
        <h1 className="page-title">PYQs Management</h1>
        {view === 'questions' && (
          <div style={{ display: 'flex', gap: '1rem' }}>
            <button className="btn-primary" onClick={() => openModal()}>
              <Plus size={18} /> Add New PYQ
            </button>
          </div>
        )}
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '2rem', color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
        <span style={{ cursor: 'pointer', color: view === 'exams' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('exams')}>Exams</span>
        {selectedExam && <> <ChevronRight size={14} /> <span style={{ cursor: 'pointer', color: view === 'subjects' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('subjects')}>{selectedExam.name}</span> </>}
        {selectedSubject && view !== 'exams' && view !== 'subjects' && <> <ChevronRight size={14} /> <span style={{ cursor: 'pointer', color: view === 'chapters' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('chapters')}>{selectedSubject.name}</span> </>}
        {selectedChapter && view === 'questions' && <> <ChevronRight size={14} /> <span style={{ color: 'var(--color-text-main)', fontWeight: 500 }}>{selectedChapter.name}</span> </>}
      </div>

      {view === 'exams' && (
        <div>
          <div style={{ position: 'relative', maxWidth: '400px', marginBottom: '1rem' }}>
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

          {loading ? (
            <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--color-text-muted)' }}>Loading questions from Firebase...</div>
          ) : Object.keys(questionsByYear).length === 0 ? (
            <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--color-text-muted)' }}>No questions found.</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {Object.entries(questionsByYear).sort((a, b) => b[0].localeCompare(a[0])).map(([year, qs]) => (
                <div key={year} className="card" style={{ padding: '0' }}>
                  <div 
                    onClick={() => toggleYear(year)}
                    style={{ 
                      padding: '1rem 1.5rem', 
                      display: 'flex', 
                      justifyContent: 'space-between', 
                      alignItems: 'center',
                      cursor: 'pointer',
                      borderBottom: expandedYears[year] ? '1px solid var(--color-border-light)' : 'none',
                      backgroundColor: 'var(--color-background-soft)'
                    }}
                  >
                    <h3 style={{ margin: 0, fontSize: '1.125rem' }}>Year {year} <span className="badge badge-primary" style={{ marginLeft: '0.5rem' }}>{qs.length} Questions</span></h3>
                    {expandedYears[year] ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
                  </div>
                  
                  {expandedYears[year] && (
                    <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                      {qs.map((q, idx) => (
                        <div key={q.id} style={{ borderLeft: '4px solid var(--color-primary)', borderBottom: '1px solid var(--color-border-light)', padding: '1rem 0 1rem 1rem', marginBottom: '0.5rem' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                            <span className="badge badge-warning">Q{idx + 1} | ID: {q.id.substring(0,6)}</span>
                            <div style={{ display: 'flex', gap: '0.5rem' }}>
                              <button className="btn-outline" onClick={() => openModal(q)} style={{ padding: '0.25rem 0.5rem', fontSize: '0.75rem', color: 'var(--color-primary)' }}>
                                <Edit size={14} style={{ marginRight: '0.25rem' }}/> Edit
                              </button>
                              <button className="btn-outline" onClick={() => handleDelete(q.id)} style={{ padding: '0.25rem 0.5rem', fontSize: '0.75rem', color: 'var(--color-danger)', borderColor: 'var(--color-danger-light)' }}>
                                <Trash2 size={14} style={{ marginRight: '0.25rem' }}/> Delete
                              </button>
                            </div>
                          </div>
                          
                          <p style={{ fontWeight: 500, marginBottom: '1rem' }}><Latex>{q.text || ''}</Latex></p>
                          
                          {(q.imageUrls || (q.imageUrl ? [q.imageUrl] : [])).map((imgUrl, imgIdx) => (
                            <img key={imgIdx} src={imgUrl} alt="Question Graphic" style={{ maxHeight: '150px', marginBottom: '1rem', borderRadius: '4px', marginRight: '1rem' }} />
                          ))}

                          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '0.5rem', marginBottom: '1rem' }}>
                            {(q.options || []).map((opt, oIdx) => (
                              <div key={oIdx} style={{ 
                                padding: '0.5rem', 
                                border: q.correctAnswer === opt || q.correctAnswer === oIdx.toString() ? '1px solid var(--color-success)' : '1px solid var(--color-border-light)',
                                backgroundColor: q.correctAnswer === opt || q.correctAnswer === oIdx.toString() ? 'var(--color-success-light)' : 'transparent',
                                borderRadius: '4px',
                                fontSize: '0.875rem',
                                display: 'flex',
                                flexDirection: 'column',
                                gap: '0.5rem'
                              }}>
                                <Latex>{opt}</Latex>
                                {q.optionImages && q.optionImages[oIdx] && (
                                  <img src={q.optionImages[oIdx]} alt="Option" style={{ maxHeight: '100px', borderRadius: '4px', alignSelf: 'flex-start' }} />
                                )}
                              </div>
                            ))}
                          </div>

                          {q.explanation && (
                            <div style={{ marginTop: '1rem', borderTop: '1px dashed var(--color-border-light)', paddingTop: '1rem', marginBottom: '1rem' }}>
                              <strong style={{ color: 'var(--color-primary)' }}>Solution / Explanation:</strong>
                              <div style={{ marginTop: '0.5rem', fontSize: '0.925rem', lineHeight: '1.5' }}>
                                <Latex>{q.explanation}</Latex>
                              </div>
                              {(q.solutionImageUrls || (q.solutionImageUrl ? [q.solutionImageUrl] : [])).map((imgUrl, imgIdx) => (
                                <img key={imgIdx} src={imgUrl} alt="Solution Graphic" style={{ maxHeight: '150px', marginTop: '0.75rem', borderRadius: '4px', display: 'inline-block', marginRight: '1rem' }} />
                              ))}
                            </div>
                          )}

                          <div style={{ fontSize: '0.875rem', color: 'var(--color-text-muted)' }}>
                            {q.date && <span style={{ marginRight: '1rem' }}><strong>Date:</strong> {q.date}</span>}
                            {q.shift && <span><strong>Shift:</strong> {q.shift}</span>}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Sidebar */}
      {isModalOpen && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 100, display: 'flex', justifyContent: 'flex-end' }}>
          <div className="card" style={{ width: '100%', maxWidth: '600px', height: '100vh', borderRadius: 0, margin: 0, overflowY: 'auto', padding: '2rem', position: 'relative' }}>
            <button onClick={closeModal} style={{ position: 'absolute', top: '1.5rem', left: '1.5rem', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-muted)' }}>
              <X size={24} />
            </button>
            <h2 style={{ marginTop: 0, marginBottom: '1.5rem', paddingLeft: '2.5rem' }}>{editingId ? 'Edit Question' : 'Add New Question'}</h2>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Question Text (Supports LaTeX with $...$)</label>
                <textarea className="form-control" rows="4" value={formData.text} onChange={e => setFormData({...formData, text: e.target.value})}></textarea>
                <div style={{ marginTop: '0.5rem', padding: '0.5rem', background: 'var(--color-background-soft)', borderRadius: '4px', fontSize: '0.875rem' }}>
                  <Latex>{formData.text}</Latex>
                </div>
              </div>

              <div style={{ marginBottom: '0.5rem' }}>
                <label className="form-label" style={{ display: 'flex', justifyContent: 'space-between' }}>
                  Question Image 
                  <span style={{ fontSize: '0.75rem', fontWeight: 'normal', color: 'var(--color-primary)', cursor: 'pointer' }}>
                    <input type="file" multiple accept="image/*" id="q-img-edit" style={{ display: 'none' }} onChange={e => handleImageUpload(e)} />
                    <label htmlFor="q-img-edit" style={{ cursor: 'pointer' }}>Upload Image(s)</label>
                  </span>
                </label>
                {(formData.imageUrls || []).map((imgUrl, imgIdx) => (
                  <div key={imgIdx} style={{ display: 'inline-block', marginRight: '1rem', marginBottom: '1rem' }}>
                    <img src={imgUrl} alt="Extracted graphic" style={{ maxWidth: '100%', maxHeight: '200px', borderRadius: 'var(--radius-sm)' }} />
                    <button className="btn-outline" style={{ display: 'block', marginTop: '0.5rem', padding: '0.25rem 0.5rem', fontSize: '0.75rem', color: 'var(--color-danger)', borderColor: 'var(--color-danger-light)' }} onClick={(e) => {
                      e.preventDefault();
                      setFormData(prev => {
                        const newUrls = prev.imageUrls.filter((_, i) => i !== imgIdx);
                        return {...prev, imageUrls: newUrls, imageUrl: newUrls.length > 0 ? newUrls[0] : ''};
                      });
                    }}>Remove</button>
                  </div>
                ))}
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem' }}>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Year</label>
                  <input type="text" className="form-control" value={formData.year} onChange={e => setFormData({...formData, year: e.target.value})} />
                </div>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Date</label>
                  <input type="text" className="form-control" value={formData.date} onChange={e => setFormData({...formData, date: e.target.value})} placeholder="e.g. 24 Jan 2023" />
                </div>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Shift (e.g., 'Morning Shift', 'Evening Shift')</label>
                  <input type="text" className="form-control" value={formData.shift} onChange={e => setFormData({...formData, shift: e.target.value})} />
                </div>

              </div>

              <div>
                <label className="form-label">Options (Check the radio button for the correct answer)</label>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '0.75rem' }}>
                  {formData.options.map((opt, i) => (
                    <div key={i} style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                      <input 
                        type="radio" 
                        name="correctAnswer"
                        checked={formData.correctAnswer === opt || formData.correctAnswer === i.toString()}
                        onChange={() => setFormData({...formData, correctAnswer: (formData.optionImages && formData.optionImages[i]) ? i.toString() : opt})}
                        style={{ width: '20px', height: '20px', flexShrink: 0 }}
                      />
                      
                      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                        <input 
                          type="text" 
                          className="form-control" 
                          value={opt} 
                          onChange={e => {
                            const newOpts = [...formData.options];
                            const wasCorrect = formData.correctAnswer === newOpts[i];
                            newOpts[i] = e.target.value;
                            setFormData({
                              ...formData, 
                              options: newOpts,
                              correctAnswer: (wasCorrect && !(formData.optionImages && formData.optionImages[i])) ? e.target.value : formData.correctAnswer
                            });
                          }} 
                          placeholder={`Option ${i+1}`}
                        />
                        
                        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                          <input type="file" accept="image/*" id={`opt-img-edit-${i}`} style={{ display: 'none' }} onChange={e => handleImageUpload(e, i)} />
                          <label htmlFor={`opt-img-edit-${i}`} style={{ fontSize: '0.75rem', color: 'var(--color-primary)', cursor: 'pointer' }}>
                            {formData.optionImages && formData.optionImages[i] ? 'Change Image' : 'Add Image'}
                          </label>
                          
                          {formData.optionImages && formData.optionImages[i] && (
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                              <img src={formData.optionImages[i]} alt={`Option ${i+1}`} style={{ height: '40px', borderRadius: '4px' }} />
                              <button className="btn-outline" style={{ padding: '0.15rem 0.25rem', fontSize: '0.7rem', color: 'var(--color-danger)', borderColor: 'var(--color-danger-light)' }} onClick={(e) => {
                                e.preventDefault();
                                const optionImages = [...(formData.optionImages || [])];
                                optionImages[i] = '';
                                setFormData(prev => ({...prev, optionImages}));
                              }}>Remove</button>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label" style={{ display: 'flex', justifyContent: 'space-between' }}>
                  Explanation (Supports LaTeX with $...$)
                  <span style={{ fontSize: '0.75rem', fontWeight: 'normal', color: 'var(--color-primary)', cursor: 'pointer' }}>
                    <input type="file" multiple accept="image/*" id="sol-img-edit" style={{ display: 'none' }} onChange={e => handleImageUpload(e, 'explanation')} />
                    <label htmlFor="sol-img-edit" style={{ cursor: 'pointer' }}>Upload Image(s)</label>
                  </span>
                </label>
                <textarea className="form-control" rows="3" value={formData.explanation} onChange={e => setFormData({...formData, explanation: e.target.value})}></textarea>
                {(formData.solutionImageUrls || []).map((imgUrl, imgIdx) => (
                  <div key={imgIdx} style={{ display: 'inline-block', marginRight: '1rem', marginTop: '0.5rem' }}>
                    <img src={imgUrl} alt="Solution graphic" style={{ maxWidth: '100%', maxHeight: '200px', borderRadius: 'var(--radius-sm)' }} />
                    <div>
                      <button className="btn-outline" style={{ marginTop: '0.5rem', padding: '0.25rem 0.5rem', fontSize: '0.75rem', color: 'var(--color-danger)', borderColor: 'var(--color-danger-light)' }} onClick={(e) => {
                        e.preventDefault();
                        setFormData(prev => {
                          const newUrls = prev.solutionImageUrls.filter((_, i) => i !== imgIdx);
                          return {...prev, solutionImageUrls: newUrls, solutionImageUrl: newUrls.length > 0 ? newUrls[0] : ''};
                        });
                      }}>Remove</button>
                    </div>
                  </div>
                ))}
                <div style={{ marginTop: '0.5rem', padding: '0.5rem', background: 'var(--color-background-soft)', borderRadius: '4px', fontSize: '0.875rem' }}>
                  <Latex>{formData.explanation}</Latex>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem', marginTop: '1rem' }}>
                <button className="btn-outline" onClick={closeModal} disabled={isSubmitting}>Cancel</button>
                <button className="btn-primary" onClick={handleSave} disabled={isSubmitting}>
                  {isSubmitting ? <Loader2 size={18} className="animate-spin" /> : 'Save Question'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PYQs;
