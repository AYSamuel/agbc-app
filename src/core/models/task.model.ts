export interface Task {
  id: string;
  title: string;
  description: string;
  deadline: Date;
  assignedTo: string;
  reminder: Date;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}
