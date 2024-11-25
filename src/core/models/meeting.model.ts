export interface Meeting {
  id: string;
  title: string;
  description: string;
  date: Date;
  location: string;
  isGlobal: boolean;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}
