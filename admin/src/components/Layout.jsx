import { useState } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { 
  UploadCloud, 
  Database, 
  FileQuestion, 
  ScrollText, 
  BookOpen, 
  Library, 
  CreditCard, 
  Users, 
  AlertCircle,
  DollarSign, 
  LogOut,
  GraduationCap,
  Settings,
  Bell,
  LifeBuoy,
  Menu,
  ChevronLeft
} from 'lucide-react';

const Layout = () => {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);

  const handleLogout = async () => {
    try {
      await logout();
      navigate('/login');
    } catch (error) {
      console.error("Logout failed", error);
    }
  };
  const menuItems = [
    { name: 'Exam Setup', path: '/exams', icon: Settings },
    { name: 'Upload Questions', path: '/upload-questions', icon: UploadCloud },
    { name: 'PYQs', path: '/pyqs', icon: Database },
    { name: 'Extra Questions', path: '/extra-questions', icon: FileQuestion },
    { name: 'Test Series', path: '/test-series', icon: ScrollText },
    { name: 'Notes', path: '/notes', icon: BookOpen },
    { name: 'Books', path: '/books', icon: Library },
    { name: 'Subscription', path: '/subscription', icon: CreditCard },
    { name: 'Users', path: '/users', icon: Users },
    { name: 'Notifications', path: '/notifications', icon: Bell },
    { name: 'Help & Support', path: '/support', icon: LifeBuoy },
    { name: 'Reports', path: '/reports', icon: AlertCircle },
    { name: 'Financial', path: '/financial', icon: DollarSign },
  ];

  return (
    <div className="app-container">
      {/* Sidebar */}
      <aside style={{
        width: isSidebarOpen ? '280px' : '80px',
        backgroundColor: 'var(--color-surface)',
        borderRight: '1px solid var(--color-border)',
        display: 'flex',
        flexDirection: 'column',
        boxShadow: 'var(--shadow-sm)',
        zIndex: 10,
        transition: 'width 0.3s ease'
      }}>
        {/* Logo Area */}
        <div style={{
          padding: isSidebarOpen ? '2rem 1.5rem' : '2rem 0',
          display: 'flex',
          alignItems: 'center',
          justifyContent: isSidebarOpen ? 'space-between' : 'center',
          flexDirection: isSidebarOpen ? 'row' : 'column',
          gap: '1rem',
          borderBottom: '1px solid var(--color-border-light)'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <div style={{
              backgroundColor: 'var(--color-primary-light)',
              color: 'var(--color-primary)',
              padding: '0.5rem',
              borderRadius: 'var(--radius-md)',
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center'
            }}>
              <GraduationCap size={28} style={{ minWidth: '28px' }} />
            </div>
            {isSidebarOpen && (
              <h2 style={{ fontSize: '1.25rem', margin: 0, color: 'var(--color-secondary)', whiteSpace: 'nowrap' }}>
                Admin Panel
              </h2>
            )}
          </div>
          <button 
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            style={{
              background: 'var(--color-surface)',
              border: '1px solid var(--color-border)',
              cursor: 'pointer',
              color: 'var(--color-text-muted)',
              display: 'flex',
              padding: '0.25rem',
              borderRadius: '50%',
              alignItems: 'center',
              justifyContent: 'center'
            }}
            title={isSidebarOpen ? "Collapse sidebar" : "Expand sidebar"}
          >
            {isSidebarOpen ? <ChevronLeft size={20} /> : <Menu size={20} />}
          </button>
        </div>

        {/* Navigation */}
        <nav style={{
          flex: 1,
          padding: '1.5rem 1rem',
          overflowY: 'auto',
          display: 'flex',
          flexDirection: 'column',
          gap: '0.5rem'
        }}>
          {menuItems.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.name}
                to={item.path}
                title={!isSidebarOpen ? item.name : ""}
                style={({ isActive }) => ({
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.75rem',
                  padding: isSidebarOpen ? '0.875rem 1rem' : '0.875rem 0',
                  justifyContent: isSidebarOpen ? 'flex-start' : 'center',
                  borderRadius: 'var(--radius-md)',
                  color: isActive ? 'var(--color-primary)' : 'var(--color-text-muted)',
                  backgroundColor: isActive ? 'var(--color-primary-light)' : 'transparent',
                  fontWeight: isActive ? 600 : 500,
                  transition: 'all var(--transition-fast)'
                })}
                className="sidebar-link"
              >
                <Icon size={20} style={{ minWidth: '20px' }} />
                {isSidebarOpen && <span style={{ whiteSpace: 'nowrap' }}>{item.name}</span>}
              </NavLink>
            );
          })}
        </nav>

        {/* Logout */}
        <div style={{ padding: '1.5rem 1rem', borderTop: '1px solid var(--color-border-light)' }}>
          <button style={{
            width: '100%',
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
            padding: isSidebarOpen ? '0.875rem 1rem' : '0.875rem 0',
            justifyContent: isSidebarOpen ? 'flex-start' : 'center',
            borderRadius: 'var(--radius-md)',
            color: 'var(--color-danger)',
            fontWeight: 500,
            transition: 'all var(--transition-fast)',
            cursor: 'pointer',
            backgroundColor: 'transparent',
            border: 'none'
          }}
          title={!isSidebarOpen ? "Logout" : ""}
          onClick={handleLogout}
          onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'var(--color-danger-light)'}
          onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
          >
            <LogOut size={20} style={{ minWidth: '20px' }} />
            {isSidebarOpen && <span>Logout</span>}
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="main-content">
        <div style={{ maxWidth: '1400px', width: '100%', margin: '0 auto' }}>
          <Outlet />
        </div>
      </main>
    </div>
  );
};

export default Layout;
