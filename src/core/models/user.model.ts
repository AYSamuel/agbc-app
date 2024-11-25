export interface User {
  id: string;
  email: string;
  displayName: string;
  role: 'admin' | 'worker' | 'member';
  location: {
    city: string;
    country: string;
  };
  createdAt: Date;
  updatedAt: Date;
}
