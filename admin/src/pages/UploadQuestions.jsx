import { useState, useEffect, useRef } from 'react';
import { Upload, Loader2, Save, Trash2, FileJson, Sparkles } from 'lucide-react';
import { addQuestion, getExams, uploadImage } from '../services/api';
import 'katex/dist/katex.min.css';
import katex from 'katex';

// Custom component to render mixed text and LaTeX
const Latex = ({ children }) => {
  if (typeof children !== 'string') return <>{children}</>;

  // Split by $ to separate math and text. 
  // Even indices are text, odd indices are math.
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

const UploadQuestions = () => {
  const [exams, setExams] = useState([]);
  const [loadingExams, setLoadingExams] = useState(true);

  // Dynamic selections
  const [selectedExamId, setSelectedExamId] = useState('');
  const [selectedSubjectName, setSelectedSubjectName] = useState('');
  const [selectedChapterName, setSelectedChapterName] = useState('');
  const [positiveMarks, setPositiveMarks] = useState(4);
  const [negativeMarks, setNegativeMarks] = useState(-1);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [stagedQuestions, setStagedQuestions] = useState([]);
  const fileInputRef = useRef(null);
  
  // AI Solution Generation State
  const [aiProgress, setAiProgress] = useState('');
  const [isExtracting, setIsExtracting] = useState(false);

  useEffect(() => {
    const fetchExamsData = async () => {
      const data = await getExams();
      setExams(data);
      setLoadingExams(false);
    };
    fetchExamsData();
  }, []);

  const selectedExam = exams.find(e => e.id === selectedExamId);
  const selectedSubject = selectedExam?.subjects?.find(s => s.name === selectedSubjectName);

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    if (!selectedExamId || !selectedSubjectName || !selectedChapterName) {
      alert("Please select Exam, Subject, and Chapter before uploading JSON.");
      e.target.value = null;
      return;
    }

    setIsExtracting(true);
    setAiProgress('Uploading file to AI for analysis and normalization...');
    
    try {
      const formData = new FormData();
      formData.append('file', file);
      
      const response = await fetch('http://localhost:8000/api/generate-missing-solutions', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Failed to process file on backend');
      }

      const streamReader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';
      
      while (true) {
        const { done, value } = await streamReader.read();
        if (done) break;
        
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        
        buffer = lines.pop() || '';
        
        for (const line of lines) {
          if (line.trim()) {
            const data = JSON.parse(line);
            if (data.status === 'progress') {
              setAiProgress(data.message);
            } else if (data.status === 'complete') {
              setAiProgress('Formatting final questions...');
              const processedQuestions = data.questions || [];
              
              const processed = processedQuestions.map(q => {
                let optionsArray = [];
                if (Array.isArray(q.options)) {
                  optionsArray = q.options;
                } else if (q.options && typeof q.options === 'object') {
                  optionsArray = Object.values(q.options);
                }
                
                let correctAnswer = q.correctAnswer ?? q.correct_option ?? q.answer ?? '';
                if (q.options && !Array.isArray(q.options) && typeof q.options === 'object') {
                   if (q.options[correctAnswer]) {
                     correctAnswer = q.options[correctAnswer];
                   }
                }

                const isInteger = optionsArray.length === 0;
                return {
                  ...q,
                  options: optionsArray,
                  correctAnswer: correctAnswer,
                  explanation: q.explanation || q.solution || '',
                  negativeMarks: q.negativeMarks !== undefined ? q.negativeMarks : (isInteger ? 0 : undefined),
                  isInteger: isInteger
                };
              });
              setStagedQuestions(processed);
            } else if (data.status === 'error') {
              alert("AI Error: " + data.message);
            }
          }
        }
      }
    } catch (error) {
      console.error(error);
      alert("Error: " + error.message);
    } finally {
      setIsExtracting(false);
      setAiProgress('');
      e.target.value = null; // reset input
    }
  };

  const handleImageUpload = async (e, qIndex, optIndex = null) => {
    const file = e.target.files[0];
    if (!file) return;

    try {
      const url = await uploadImage(file);
      const newQ = [...stagedQuestions];
      if (optIndex === null) {
        newQ[qIndex] = { ...newQ[qIndex], imageUrl: url };
      } else {
        const optionImages = [...(newQ[qIndex].optionImages || ["", "", "", ""])];
        optionImages[optIndex] = url;
        newQ[qIndex] = { ...newQ[qIndex], optionImages };
      }
      setStagedQuestions(newQ);
    } catch (err) {
      alert("Failed to upload image.");
    } finally {
      e.target.value = null;
    }
  };

  const handleSaveStaged = async () => {
    if (!selectedExamId || !selectedSubjectName || !selectedChapterName) {
      alert("Please select Exam, Subject, and Chapter before saving.");
      return;
    }

    setIsSubmitting(true);
    try {
      for (const q of stagedQuestions) {
        await addQuestion({
          ...q,
          examId: selectedExamId,
          examName: selectedExam?.name || '',
          subject: selectedSubjectName,
          chapter: selectedChapterName,
          type: q.type || 'pyq',
          isInteger: q.isInteger || (!q.options || q.options.length === 0),
          year: q.year || new Date().getFullYear().toString(),
          marks: q.marks !== undefined ? q.marks : positiveMarks,
          negativeMarks: q.negativeMarks !== undefined ? q.negativeMarks : ((!q.options || q.options.length === 0) ? 0 : negativeMarks),
          date: q.date || '',
          shift: q.shift || '',
          imageUrl: q.imageUrl || '',
          optionImages: q.optionImages || []
        });
      }
      alert("All extracted questions saved successfully!");
      setStagedQuestions([]);
    } catch (error) {
      console.error(error);
      alert("Error saving questions: " + error.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1200px', margin: '0 auto' }}>
      <div className="page-header" style={{ marginBottom: '2rem' }}>
        <h1 className="page-title" style={{ fontSize: '2rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <FileJson style={{ color: 'var(--color-primary)' }} size={32} />
          Upload JSON Questions
        </h1>
        <p style={{ color: 'var(--color-text-muted)', marginTop: '0.5rem' }}>
          Upload your JSON file. Our AI will automatically generate detailed step-by-step solutions for any questions that are missing an explanation.
        </p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>

        {/* Configuration Card */}
        <div className="card" style={{ padding: '2rem', borderTop: '4px solid var(--color-primary)' }}>
          <h3 style={{ marginBottom: '1.5rem', fontSize: '1.25rem', color: 'var(--color-secondary)' }}>1. Select Target Categories</h3>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1.5rem' }}>
            <div className="form-group" style={{ flex: '1 1 200px' }}>
              <label className="form-label">Exam Name</label>
              <select className="form-control" style={{ padding: '0.75rem', borderRadius: 'var(--radius-md)' }} value={selectedExamId} onChange={e => { setSelectedExamId(e.target.value); setSelectedSubjectName(''); setSelectedChapterName(''); }}>
                <option value="">Select Exam...</option>
                {exams.map(e => <option key={e.id} value={e.id}>{e.name}</option>)}
              </select>
            </div>

            <div className="form-group" style={{ flex: '1 1 200px' }}>
              <label className="form-label">Subject</label>
              <select className="form-control" style={{ padding: '0.75rem', borderRadius: 'var(--radius-md)' }} value={selectedSubjectName} onChange={e => { setSelectedSubjectName(e.target.value); setSelectedChapterName(''); }} disabled={!selectedExamId}>
                <option value="">Select Subject...</option>
                {selectedExam?.subjects?.map((sub, i) => <option key={i} value={sub.name}>{sub.name}</option>)}
              </select>
            </div>

            <div className="form-group" style={{ flex: '1 1 200px' }}>
              <label className="form-label">Chapter</label>
              <select className="form-control" style={{ padding: '0.75rem', borderRadius: 'var(--radius-md)' }} value={selectedChapterName} onChange={e => setSelectedChapterName(e.target.value)} disabled={!selectedSubjectName}>
                <option value="">Select Chapter...</option>
                {selectedSubject?.chapters?.map((chap, i) => <option key={i} value={chap}>{chap}</option>)}
              </select>
            </div>

            <div className="form-group" style={{ flex: '0 0 100px' }}>
              <label className="form-label">Default +ve</label>
              <input type="number" className="form-control" value={positiveMarks} onChange={e => setPositiveMarks(Number(e.target.value))} style={{ padding: '0.75rem', textAlign: 'center' }} />
            </div>

            <div className="form-group" style={{ flex: '0 0 100px' }}>
              <label className="form-label">Default -ve</label>
              <input type="number" className="form-control" value={negativeMarks} onChange={e => setNegativeMarks(Number(e.target.value))} style={{ padding: '0.75rem', textAlign: 'center' }} />
            </div>
          </div>
        </div>

        {/* Upload Area */}
        <div className="card" style={{ 
            padding: '3rem 2rem', 
            textAlign: 'center', 
            backgroundColor: 'var(--color-primary-light)', 
            border: '2px dashed var(--color-primary)', 
            display: 'flex', 
            flexDirection: 'column', 
            alignItems: 'center',
            justifyContent: 'center',
            gap: '1.5rem',
            transition: 'all var(--transition-normal)'
          }}>
          
          <div style={{ 
            backgroundColor: 'var(--color-surface)', 
            padding: '1.5rem', 
            borderRadius: '50%', 
            boxShadow: 'var(--shadow-md)',
            color: 'var(--color-primary)'
          }}>
            {isExtracting ? <Sparkles size={40} className="animate-pulse" /> : <Upload size={40} />}
          </div>

          <div>
            <h3 style={{ fontSize: '1.5rem', marginBottom: '0.5rem', color: 'var(--color-primary-hover)' }}>
              {isExtracting ? 'AI is Processing JSON...' : 'Upload JSON Questions'}
            </h3>
            <p style={{ color: 'var(--color-text-muted)' }}>
              {isExtracting ? (
                <span style={{ fontWeight: '500', color: 'var(--color-primary)' }}>{aiProgress}</span>
              ) : (
                'Select a properly formatted JSON file to upload and process.'
              )}
            </p>
          </div>

          <input
            type="file"
            accept=".json"
            style={{ display: 'none' }}
            ref={fileInputRef}
            onChange={handleFileUpload}
          />
          
          <button 
            className="btn-primary" 
            onClick={() => fileInputRef.current.click()} 
            style={{ 
              padding: '1rem 2.5rem', 
              fontSize: '1.125rem', 
              boxShadow: '0 10px 15px -3px rgba(79, 70, 229, 0.3)',
              borderRadius: '2rem'
            }}
            disabled={isExtracting}
          >
            {isExtracting ? (
              <><Loader2 size={20} className="animate-spin" /> Processing...</>
            ) : (
              <><FileJson size={20} /> Select JSON File</>
            )}
          </button>
        </div>

        {/* Staged Questions Area */}
        {stagedQuestions.length > 0 && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', marginTop: '1rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0 0.5rem' }}>
              <h3 style={{ fontSize: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <span style={{ backgroundColor: 'var(--color-success)', color: 'white', padding: '0.25rem 0.75rem', borderRadius: '1rem', fontSize: '1rem' }}>
                  {stagedQuestions.length}
                </span>
                Processed Questions Ready
              </h3>
              <button className="btn-outline" onClick={() => setStagedQuestions([])} style={{ color: 'var(--color-danger)', borderColor: 'var(--color-danger-light)', padding: '0.5rem 1rem' }}>
                <Trash2 size={16} style={{ marginRight: '0.5rem' }} /> Discard All
              </button>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
              {stagedQuestions.map((q, idx) => (
                <div key={idx} className="card" style={{ padding: '2rem', borderLeft: '6px solid var(--color-success)', position: 'relative' }}>
                  
                  <div style={{ position: 'absolute', top: '1.5rem', right: '1.5rem' }}>
                    <button className="btn-outline" onClick={() => setStagedQuestions(prev => prev.filter((_, i) => i !== idx))} style={{ color: 'var(--color-danger)', borderColor: 'var(--color-danger-light)', padding: '0.25rem 0.5rem', fontSize: '0.75rem' }}>
                      <Trash2 size={14} style={{ marginRight: '4px' }} /> Delete
                    </button>
                  </div>

                  <span className="badge" style={{ backgroundColor: 'var(--color-success-light)', color: 'var(--color-success)', padding: '0.5rem 1rem', fontSize: '1rem', fontWeight: 'bold', marginBottom: '1.5rem', display: 'inline-block' }}>
                    Question {idx + 1}
                  </span>

                  <div className="form-group">
                    <label className="form-label" style={{ fontSize: '1.1rem' }}>Question Text</label>
                    <textarea className="form-control" rows="4" value={q.text || ''} style={{ fontSize: '1rem', padding: '1rem' }} onChange={e => {
                      const newQ = [...stagedQuestions];
                      newQ[idx] = { ...newQ[idx], text: e.target.value };
                      setStagedQuestions(newQ);
                    }} />
                    <div style={{ marginTop: '0.75rem', fontSize: '1rem', padding: '1rem', backgroundColor: '#f8fafc', borderRadius: 'var(--radius-md)', border: '1px solid #e2e8f0' }}>
                      <strong style={{ color: 'var(--color-primary)' }}>Live Preview:</strong> <div style={{ marginTop: '0.5rem' }}><Latex>{q.text || ''}</Latex></div>
                    </div>
                  </div>

                  <div style={{ marginBottom: '2rem' }}>
                    <label className="form-label" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span>Question Graphic (Optional)</span>
                      <span style={{ fontSize: '0.875rem', fontWeight: '500', color: 'var(--color-primary)', cursor: 'pointer', backgroundColor: 'var(--color-primary-light)', padding: '0.25rem 0.75rem', borderRadius: '1rem' }}>
                        <input type="file" accept="image/*" id={`q-img-${idx}`} style={{ display: 'none' }} onChange={e => handleImageUpload(e, idx)} />
                        <label htmlFor={`q-img-${idx}`} style={{ cursor: 'pointer' }}>+ Upload Image</label>
                      </span>
                    </label>
                    {q.imageUrl && (
                      <div style={{ marginTop: '1rem', padding: '1rem', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-md)', display: 'inline-block' }}>
                        <img src={q.imageUrl} alt="Graphic" style={{ maxWidth: '100%', maxHeight: '250px', borderRadius: 'var(--radius-sm)' }} />
                        <div style={{ marginTop: '0.5rem' }}>
                          <button className="btn-outline" style={{ padding: '0.25rem 0.5rem', fontSize: '0.75rem', color: 'var(--color-danger)', borderColor: 'var(--color-danger-light)' }} onClick={() => {
                            const newQ = [...stagedQuestions];
                            newQ[idx] = { ...newQ[idx], imageUrl: '' };
                            setStagedQuestions(newQ);
                          }}>Remove Image</button>
                        </div>
                      </div>
                    )}
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1.5rem', marginBottom: '2rem', padding: '1.5rem', backgroundColor: '#f8fafc', borderRadius: 'var(--radius-lg)' }}>
                    <label className="form-label" style={{ fontSize: '1.1rem', marginBottom: '0' }}>{(!q.options || q.options.length === 0) ? 'Integer Answer' : 'Options & Correct Answer'}</label>
                    {(!q.options || q.options.length === 0) ? (
                      <div className="form-group" style={{ marginBottom: 0 }}>
                        <input type="number" className="form-control" value={q.correctAnswer ?? ''} placeholder="Enter integer answer" style={{ fontSize: '1.2rem', padding: '1rem' }} onChange={e => {
                          const newQ = [...stagedQuestions];
                          newQ[idx] = { ...newQ[idx], correctAnswer: e.target.value };
                          setStagedQuestions(newQ);
                        }} />
                      </div>
                    ) : (
                      <div style={{ display: 'grid', gap: '1rem' }}>
                        {(q.options || []).map((opt, oIdx) => (
                          <div key={oIdx} style={{ display: 'flex', gap: '1rem', alignItems: 'center', backgroundColor: 'white', padding: '1rem', borderRadius: 'var(--radius-md)', border: q.correctAnswer === opt || q.correctAnswer === oIdx.toString() ? '2px solid var(--color-success)' : '1px solid var(--color-border)' }}>
                            <input type="radio" name={`correct-${idx}`} checked={q.correctAnswer === opt || q.correctAnswer === oIdx.toString()} onChange={() => {
                              const newQ = [...stagedQuestions];
                              newQ[idx] = { ...newQ[idx], correctAnswer: (q.optionImages && q.optionImages[oIdx]) ? oIdx.toString() : opt };
                              setStagedQuestions(newQ);
                            }} style={{ width: '24px', height: '24px', flexShrink: 0, accentColor: 'var(--color-success)' }} />

                            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                              <input type="text" className="form-control" value={opt} placeholder={`Option ${String.fromCharCode(65 + oIdx)} Text`} onChange={e => {
                                const newQ = [...stagedQuestions];
                                const newOptions = [...(newQ[idx].options || [])];

                                const wasCorrect = newQ[idx].correctAnswer === newOptions[oIdx];
                                newOptions[oIdx] = e.target.value;
                                newQ[idx].options = newOptions;
                                if (wasCorrect && !(q.optionImages && q.optionImages[oIdx])) {
                                  newQ[idx].correctAnswer = e.target.value;
                                }

                                setStagedQuestions(newQ);
                              }} />

                              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                <input type="file" accept="image/*" id={`opt-img-${idx}-${oIdx}`} style={{ display: 'none' }} onChange={e => handleImageUpload(e, idx, oIdx)} />
                                <label htmlFor={`opt-img-${idx}-${oIdx}`} style={{ fontSize: '0.875rem', fontWeight: '500', color: 'var(--color-primary)', cursor: 'pointer', backgroundColor: 'var(--color-primary-light)', padding: '0.25rem 0.75rem', borderRadius: '1rem' }}>
                                  {q.optionImages && q.optionImages[oIdx] ? 'Change Image' : '+ Add Image'}
                                </label>

                                {q.optionImages && q.optionImages[oIdx] && (
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                                    <img src={q.optionImages[oIdx]} alt={`Option ${oIdx + 1}`} style={{ height: '50px', borderRadius: '4px', border: '1px solid #e2e8f0' }} />
                                    <button className="btn-outline" style={{ padding: '0.25rem 0.5rem', fontSize: '0.75rem', color: 'var(--color-danger)', borderColor: 'var(--color-danger-light)' }} onClick={(e) => {
                                      e.preventDefault();
                                      const newQ = [...stagedQuestions];
                                      const optionImages = [...(newQ[idx].optionImages || [])];
                                      optionImages[oIdx] = '';
                                      newQ[idx] = { ...newQ[idx], optionImages };
                                      setStagedQuestions(newQ);
                                    }}>Remove</button>
                                  </div>
                                )}
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  <div className="form-group" style={{ marginBottom: '2rem' }}>
                    <label className="form-label" style={{ fontSize: '1.1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <Sparkles size={18} style={{ color: 'var(--color-warning)' }} />
                      Detailed Solution / Explanation
                    </label>
                    <textarea className="form-control" rows="5" value={q.explanation || ''} style={{ fontSize: '1rem', padding: '1rem', borderColor: 'var(--color-warning)' }} onChange={e => {
                      const newQ = [...stagedQuestions];
                      newQ[idx] = { ...newQ[idx], explanation: e.target.value };
                      setStagedQuestions(newQ);
                    }} />
                    {q.explanation && (
                      <div style={{ marginTop: '0.75rem', fontSize: '1rem', padding: '1rem', backgroundColor: '#fffbeb', borderRadius: 'var(--radius-md)', border: '1px solid #fde68a' }}>
                        <strong style={{ color: 'var(--color-warning)' }}>Preview:</strong> <div style={{ marginTop: '0.5rem' }}><Latex>{q.explanation}</Latex></div>
                      </div>
                    )}
                  </div>

                  <div style={{ display: 'flex', gap: '1.5rem', flexWrap: 'wrap', backgroundColor: '#f1f5f9', padding: '1.5rem', borderRadius: 'var(--radius-md)' }}>
                    <div className="form-group" style={{ flex: '1 1 120px', marginBottom: 0 }}>
                      <label className="form-label">Marks</label>
                      <input type="number" className="form-control" value={q.marks !== undefined ? q.marks : positiveMarks} onChange={e => {
                        const newQ = [...stagedQuestions];
                        newQ[idx] = { ...newQ[idx], marks: parseInt(e.target.value) || 0 };
                        setStagedQuestions(newQ);
                      }} />
                    </div>
                    <div className="form-group" style={{ flex: '1 1 120px', marginBottom: 0 }}>
                      <label className="form-label">Negative Marks</label>
                      <input type="number" className="form-control" value={q.negativeMarks !== undefined ? q.negativeMarks : negativeMarks} onChange={e => {
                        const newQ = [...stagedQuestions];
                        newQ[idx] = { ...newQ[idx], negativeMarks: parseInt(e.target.value) || 0 };
                        setStagedQuestions(newQ);
                      }} />
                    </div>
                    <div className="form-group" style={{ flex: '1 1 100px', marginBottom: 0 }}>
                      <label className="form-label">Year</label>
                      <input type="text" className="form-control" value={q.year || ''} placeholder="e.g. 2023" onChange={e => {
                        const newQ = [...stagedQuestions];
                        newQ[idx] = { ...newQ[idx], year: e.target.value };
                        setStagedQuestions(newQ);
                      }} />
                    </div>
                    <div className="form-group" style={{ flex: '1 1 200px', marginBottom: 0 }}>
                      <label className="form-label">Date (Exam Date)</label>
                      <input type="text" className="form-control" value={q.date || ''} placeholder="e.g. 24 Jan 2023" onChange={e => {
                        const newQ = [...stagedQuestions];
                        newQ[idx] = { ...newQ[idx], date: e.target.value };
                        setStagedQuestions(newQ);
                      }} />
                    </div>
                    <div className="form-group" style={{ flex: '1 1 150px', marginBottom: 0 }}>
                      <label className="form-label">Shift</label>
                      <input type="text" className="form-control" value={q.shift || ''} placeholder="e.g. Morning Shift" onChange={e => {
                        const newQ = [...stagedQuestions];
                        newQ[idx] = { ...newQ[idx], shift: e.target.value };
                        setStagedQuestions(newQ);
                      }} />
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div style={{ position: 'sticky', bottom: '2rem', zIndex: 50, display: 'flex', justifyContent: 'center', marginTop: '2rem' }}>
              <button className="btn-primary" onClick={handleSaveStaged} disabled={isSubmitting} style={{ 
                padding: '1.25rem 4rem', 
                fontSize: '1.25rem', 
                boxShadow: '0 20px 25px -5px rgba(79, 70, 229, 0.4)',
                borderRadius: '3rem',
                backgroundColor: 'var(--color-primary)',
                transition: 'all 0.2s ease'
              }}>
                {isSubmitting ? <Loader2 size={28} className="animate-spin" /> : <Save size={28} style={{ marginRight: '0.75rem' }} />}
                Save All {stagedQuestions.length} Questions
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default UploadQuestions;
