import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  BarChart3,
  FileText,
  Settings,
  Heart,
  MessageSquare,
  LogOut,
} from 'lucide-react';

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/users', icon: Users, label: 'Usuarios' },
  { to: '/analytics', icon: BarChart3, label: 'Analíticas' },
  { to: '/content', icon: FileText, label: 'Contenido' },
  { to: '/conversations', icon: MessageSquare, label: 'Conversaciones' },
  { to: '/settings', icon: Settings, label: 'Configuración' },
];

interface SidebarProps {
  onSignOut?: () => void;
}

export function Sidebar({ onSignOut }: SidebarProps) {
  return (
    <aside className="w-64 bg-sidebar text-white min-h-screen flex flex-col">
      {/* Logo */}
      <div className="p-6 border-b border-white/10">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
            <Heart className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-lg font-semibold">Sentio</h1>
            <p className="text-xs text-white/50">Admin Dashboard</p>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4 space-y-1">
        {navItems.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-primary text-white'
                  : 'text-white/60 hover:bg-sidebar-hover hover:text-white'
              }`
            }
          >
            <Icon className="w-5 h-5" />
            {label}
          </NavLink>
        ))}
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-white/10">
        {onSignOut && (
          <button
            onClick={onSignOut}
            className="flex items-center gap-2 w-full px-4 py-2.5 rounded-xl text-sm text-white/50 hover:text-white hover:bg-sidebar-hover transition-colors"
          >
            <LogOut className="w-4 h-4" />
            Cerrar sesión
          </button>
        )}
        <p className="text-xs text-white/30 text-center mt-3">Sentio Admin v1.0</p>
      </div>
    </aside>
  );
}
