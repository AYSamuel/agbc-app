export interface Meeting {
  id: string;
  title: string;
  description: string;
  date: Date;
  location: string;
  isGlobal: boolean;
  city?: string; // Optional, required if isGlobal is false
  country?: string; // Optional, required if isGlobal is false
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}
