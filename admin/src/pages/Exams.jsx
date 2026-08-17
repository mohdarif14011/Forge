import { useState, useEffect } from 'react';
import { Plus, Trash2, Save, Loader2, BookOpen, Edit2, X } from 'lucide-react';
import { addExam, getExams, updateExam, deleteExam } from '../services/api';

const Exams = () => {
  const [exams, setExams] = useState([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  
  // Form State
  const [editingId, setEditingId] = useState(null);
  const [name, setName] = useState('');
  const [logo, setLogo] = useState('');
  const [years, setYears] = useState('');
  
  // Dynamic Subjects & Chapters
  const [subjects, setSubjects] = useState([{ name: '', chapters: '' }]);

  useEffect(() => {
    fetchExams();
  }, []);

  const fetchExams = async () => {
    setLoading(true);
    const data = await getExams();
    setExams(data);
    setLoading(false);
  };

  const handleAddSubject = () => {
    setSubjects([...subjects, { name: '', chapters: '' }]);
  };

  const handleSubjectChange = (index, field, value) => {
    const updated = [...subjects];
    updated[index][field] = value;
    setSubjects(updated);
  };

  const handleRemoveSubject = (index) => {
    const updated = subjects.filter((_, i) => i !== index);
    setSubjects(updated);
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    
    // Parse the lists
    const parsedYears = years.split(',').map(y => y.trim()).filter(Boolean);
    const parsedSubjects = subjects.map(sub => ({
      name: sub.name.trim(),
      chapters: sub.chapters.split(',').map(c => c.trim()).filter(Boolean)
    })).filter(sub => sub.name);

    try {
      if (editingId) {
        await updateExam(editingId, {
          name,
          logo,
          years: parsedYears,
          subjects: parsedSubjects
        });
      } else {
        await addExam({
          name,
          logo,
          years: parsedYears,
          subjects: parsedSubjects
        });
      }
      
      resetForm();
      fetchExams();
    } catch (error) {
      console.error(error);
      alert("Failed to save exam: " + error.message);
    } finally {
      setSaving(false);
    }
  };

  const resetForm = () => {
    setEditingId(null);
    setName('');
    setLogo('');
    setYears('');
    setSubjects([{ name: '', chapters: '' }]);
  };

  const handleEdit = (exam) => {
    setEditingId(exam.id);
    setName(exam.name || '');
    setLogo(exam.logo || '');
    setYears(exam.years?.join(', ') || '');
    if (exam.subjects && exam.subjects.length > 0) {
      setSubjects(exam.subjects.map(s => ({
        name: s.name,
        chapters: s.chapters?.join(', ') || ''
      })));
    } else {
      setSubjects([{ name: '', chapters: '' }]);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this exam?")) return;
    try {
      await deleteExam(id);
      if (editingId === id) resetForm();
      fetchExams();
    } catch (error) {
      console.error(error);
      alert("Failed to delete exam: " + error.message);
    }
  };

  return (
    <div className="animate-fade-in">
      <div className="page-header">
        <h1 className="page-title">Exam Configuration</h1>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
        {/* Left Side: Create Form */}
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
            <h2 style={{ fontSize: '1.25rem', display: 'flex', alignItems: 'center', gap: '0.5rem', margin: 0 }}>
              <BookOpen size={20} color="var(--color-primary)" />
              {editingId ? 'Edit Exam' : 'Add New Exam'}
            </h2>
            {editingId && (
              <button type="button" className="btn-icon" onClick={resetForm} title="Cancel Edit">
                <X size={20} />
              </button>
            )}
          </div>

          <form onSubmit={handleSave}>
            <div className="form-group">
              <label className="form-label">Exam Name</label>
              <input type="text" className="form-control" placeholder="e.g. JEE Mains" value={name} onChange={(e) => setName(e.target.value)} required />
            </div>
            
            <div className="form-group">
              <label className="form-label">Exam Logo URL (or abbreviation)</label>
              <input type="text" className="form-control" placeholder="e.g. JM or https://..." value={logo} onChange={(e) => setLogo(e.target.value)} />
            </div>

            <div className="form-group">
              <label className="form-label">Available Years (comma separated)</label>
              <input type="text" className="form-control" placeholder="2024, 2023, 2022" value={years} onChange={(e) => setYears(e.target.value)} />
            </div>

            <div style={{ borderTop: '1px solid var(--color-border-light)', margin: '2rem 0', paddingTop: '1.5rem' }}>
              <h3 style={{ fontSize: '1rem', marginBottom: '1rem' }}>Subjects & Chapters</h3>
              
              {subjects.map((sub, index) => (
                <div key={index} style={{ backgroundColor: 'var(--color-background)', padding: '1rem', borderRadius: 'var(--radius-md)', marginBottom: '1rem', position: 'relative' }}>
                  {subjects.length > 1 && (
                    <button type="button" onClick={() => handleRemoveSubject(index)} style={{ position: 'absolute', top: '0.5rem', right: '0.5rem', color: 'var(--color-danger)' }}>
                      <Trash2 size={16} />
                    </button>
                  )}
                  <div className="form-group">
                    <label className="form-label">Subject Name</label>
                    <input type="text" className="form-control" placeholder="e.g. Physics" value={sub.name} onChange={(e) => handleSubjectChange(index, 'name', e.target.value)} required />
                  </div>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Chapters (comma separated)</label>
                    <textarea className="form-control" rows="2" placeholder="Kinematics, Thermodynamics..." value={sub.chapters} onChange={(e) => handleSubjectChange(index, 'chapters', e.target.value)}></textarea>
                  </div>
                </div>
              ))}

              <button type="button" className="btn-outline" onClick={handleAddSubject} style={{ width: '100%' }}>
                <Plus size={16} /> Add Another Subject
              </button>
            </div>

            <button type="submit" className="btn-primary" style={{ width: '100%', padding: '0.875rem' }} disabled={saving}>
              {saving ? <Loader2 size={18} className="animate-spin" /> : <Save size={18} />}
              {editingId ? 'Update Exam Configuration' : 'Save Exam Configuration'}
            </button>
          </form>
        </div>

        {/* Right Side: List of Exams */}
        <div className="card">
          <h2 style={{ fontSize: '1.25rem', marginBottom: '1.5rem' }}>Configured Exams</h2>
          
          {loading ? (
            <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--color-text-muted)' }}>Loading...</div>
          ) : exams.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '2rem', backgroundColor: 'var(--color-background)', borderRadius: 'var(--radius-md)', color: 'var(--color-text-muted)' }}>
              No exams configured yet. Add one from the left.
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {exams.map(exam => (
                <div key={exam.id} style={{ border: '1px solid var(--color-border)', padding: '1rem', borderRadius: 'var(--radius-md)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1rem' }}>
                    <div style={{ width: '48px', height: '48px', backgroundColor: 'var(--color-primary-light)', color: 'var(--color-primary)', borderRadius: 'var(--radius-md)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
                      {exam.logo || exam.name.substring(0, 2).toUpperCase()}
                    </div>
                    <h3 style={{ margin: 0, flex: 1 }}>{exam.name}</h3>
                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      <button className="btn-icon" onClick={() => handleEdit(exam)} style={{ color: 'var(--color-primary)' }}>
                        <Edit2 size={18} />
                      </button>
                      <button className="btn-icon" onClick={() => handleDelete(exam.id)} style={{ color: 'var(--color-danger)' }}>
                        <Trash2 size={18} />
                      </button>
                    </div>
                  </div>
                  
                  <div style={{ fontSize: '0.875rem' }}>
                    <strong>Years:</strong> {exam.years?.join(', ') || 'N/A'}
                  </div>
                  
                  <div style={{ marginTop: '1rem', paddingTop: '1rem', borderTop: '1px dashed var(--color-border)' }}>
                    <strong>Subjects:</strong>
                    <ul style={{ paddingLeft: '1.5rem', marginTop: '0.5rem', fontSize: '0.875rem' }}>
                      {exam.subjects?.map((sub, i) => (
                        <li key={i}>{sub.name} ({sub.chapters?.length || 0} chapters)</li>
                      ))}
                    </ul>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Exams;
