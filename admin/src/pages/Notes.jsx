import { useState, useEffect } from 'react';
import { Search, ChevronRight, Upload, Trash2, FileText } from 'lucide-react';
import { getExams, getNotes, addNote, deleteNote } from '../services/api';

const Notes = () => {
  const [view, setView] = useState('exams'); // exams | subjects | chapters | notes
  const [selectedExam, setSelectedExam] = useState(null);
  const [selectedSubject, setSelectedSubject] = useState(null);
  const [selectedChapter, setSelectedChapter] = useState(null);

  const [exams, setExams] = useState([]);
  const [notes, setNotes] = useState([]);
  const [loading, setLoading] = useState(false);
  const [notesLoading, setNotesLoading] = useState(false);

  useEffect(() => {
    const fetchExamsData = async () => {
      setLoading(true);
      const data = await getExams();
      setExams(data);
      setLoading(false);
    };
    fetchExamsData();
  }, []);

  const handleExamClick = (exam) => { setSelectedExam(exam); setView('subjects'); };
  const handleSubjectClick = (sub) => { setSelectedSubject(sub); setView('chapters'); };
  const handleChapterClick = (chap) => { 
    setSelectedChapter(chap); 
    setView('notes'); 
    fetchNotes(chap.name);
  };
  const handleBack = (toView) => { setView(toView); };

  const fetchNotes = async (chapterName) => {
    setNotesLoading(true);
    const allNotes = await getNotes();
    setNotes(allNotes.filter(n => n.chapter === chapterName && n.subject === selectedSubject.name && n.examId === selectedExam.id));
    setNotesLoading(false);
  };

  const handleDeleteNote = async (id) => {
    await deleteNote(id);
    fetchNotes(selectedChapter.name);
  };

  const [uploading, setUploading] = useState(false);

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    // Cloudinary details (ensure these are set in .env.local)
    const cloudName = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME;
    const uploadPreset = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET;

    if (!cloudName || !uploadPreset) {
      alert('Cloudinary credentials missing in .env.local! Need VITE_CLOUDINARY_CLOUD_NAME and VITE_CLOUDINARY_UPLOAD_PRESET');
      return;
    }

    setUploading(true);
    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', uploadPreset);

    try {
      // 1. Upload to Cloudinary
      const res = await fetch(`https://api.cloudinary.com/v1_1/${cloudName}/auto/upload`, {
        method: 'POST',
        body: formData,
      });
      const data = await res.json();
      
      if (!data.secure_url) throw new Error(data.error?.message || 'Upload failed');

      let finalUrl = data.secure_url;
      if (finalUrl.includes('res.cloudinary.com') && !finalUrl.endsWith('.pdf')) {
        finalUrl += '.pdf';
      }

      // 2. Save to Firestore
      await addNote({
        title: file.name,
        pdfUrl: finalUrl,
        size: (file.size / (1024 * 1024)).toFixed(2) + ' MB',
        date: new Date().toLocaleDateString(),
        chapter: selectedChapter.name,
        subject: selectedSubject.name,
        examId: selectedExam.id,
        pages: data.pages || 1 // Cloudinary often returns page count for PDFs
      });

      alert('Note uploaded successfully!');
      fetchNotes(selectedChapter.name);
    } catch (err) {
      console.error(err);
      alert('Error uploading file: ' + err.message);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="page-header" style={{ marginBottom: '1rem' }}>
        <h1 className="page-title">Notes Management</h1>
      </div>

      {/* Breadcrumbs */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '2rem', color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
        <span style={{ cursor: 'pointer', color: view === 'exams' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('exams')}>Exams</span>
        {selectedExam && <> <ChevronRight size={14} /> <span style={{ cursor: 'pointer', color: view === 'subjects' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('subjects')}>{selectedExam.name}</span> </>}
        {selectedSubject && view !== 'exams' && view !== 'subjects' && <> <ChevronRight size={14} /> <span style={{ cursor: 'pointer', color: view === 'chapters' ? 'var(--color-primary)' : 'inherit' }} onClick={() => handleBack('chapters')}>{selectedSubject.name}</span> </>}
        {selectedChapter && view === 'notes' && <> <ChevronRight size={14} /> <span style={{ color: 'var(--color-text-main)', fontWeight: 500 }}>{selectedChapter.name}</span> </>}
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

      {view === 'subjects' && selectedExam && (
        <div className="exam-grid">
          {(selectedExam.subjects || []).length === 0 ? (
            <div style={{ padding: '2rem', textAlign: 'center', gridColumn: '1 / -1', color: 'var(--color-text-muted)' }}>No subjects found.</div>
          ) : selectedExam.subjects.map((sub, i) => (
            <div key={i} className="card exam-card" style={{ padding: '1.5rem' }} onClick={() => handleSubjectClick(sub)}>
              <h3 style={{ margin: 0, fontSize: '1.125rem' }}>{sub.name}</h3>
            </div>
          ))}
        </div>
      )}

      {view === 'chapters' && selectedSubject && (
        <div className="table-wrapper">
          <table className="data-table">
            <thead><tr><th>Chapter Name</th><th>Action</th></tr></thead>
            <tbody>
              {(selectedSubject.chapters || []).length === 0 ? (
                <tr><td colSpan="2" style={{ textAlign: 'center', padding: '2rem' }}>No chapters configured.</td></tr>
              ) : selectedSubject.chapters.map((chap, i) => (
                <tr key={i}>
                  <td style={{ fontWeight: 500 }}>{chap}</td>
                  <td><button className="btn-outline" onClick={() => handleChapterClick({ name: chap })} style={{ padding: '0.25rem 0.75rem', fontSize: '0.875rem' }}>Manage Notes</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {view === 'notes' && (
        <div>
          <div className="card" style={{ backgroundColor: 'var(--color-primary-light)', borderColor: 'var(--color-primary)', textAlign: 'center', padding: '2rem', borderStyle: 'dashed', marginBottom: '2rem' }}>
            <Upload size={32} color="var(--color-primary)" style={{ margin: '0 auto 1rem auto' }} />
            <h3 style={{ color: 'var(--color-primary)', marginBottom: '0.5rem' }}>Upload PDF Notes</h3>
            <label className="btn-primary" style={{ display: 'inline-block', marginTop: '1rem', cursor: uploading ? 'not-allowed' : 'pointer', opacity: uploading ? 0.7 : 1 }}>
              {uploading ? 'Uploading...' : 'Select PDF File'}
              <input type="file" accept=".pdf" style={{ display: 'none' }} onChange={handleFileUpload} disabled={uploading} />
            </label>
          </div>

          <div className="table-wrapper">
            <table className="data-table">
              <thead>
                <tr>
                  <th>File Name</th>
                  <th>Size</th>
                  <th>Upload Date</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {notesLoading ? (
                  <tr><td colSpan="4" style={{ textAlign: 'center', padding: '2rem' }}>Loading notes...</td></tr>
                ) : notes.length === 0 ? (
                  <tr>
                    <td colSpan="4" style={{ textAlign: 'center', padding: '2rem', color: 'var(--color-text-muted)' }}>
                      No notes uploaded yet.
                    </td>
                  </tr>
                ) : (
                  notes.map(note => (
                    <tr key={note.id}>
                      <td style={{ fontWeight: 500 }}><FileText size={16} style={{ display: 'inline', marginRight: '0.5rem', verticalAlign: 'text-bottom' }}/>{note.title}</td>
                      <td>{note.size}</td>
                      <td>{note.date}</td>
                      <td style={{ textAlign: 'right' }}>
                        <a href={note.pdfUrl} target="_blank" rel="noopener noreferrer" className="btn-icon" style={{ color: 'var(--color-primary)', marginRight: '0.5rem' }} title="View PDF">
                          <Search size={18} />
                        </a>
                        <button className="btn-icon" style={{ color: 'var(--color-danger)' }} onClick={() => handleDeleteNote(note.id)} title="Delete Note">
                          <Trash2 size={18} />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default Notes;
