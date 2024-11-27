export interface Task {
  id: string;
  title: string;
  description: string;
  deadline: Date;
  assignedTo: string | null;
  reminder: Date;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
  status: 'pending' | 'in-progress' | 'completed';
}
