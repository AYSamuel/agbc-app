export interface User {
  uid: string;
  email: string;
  displayName: string;
  role: 'admin' | 'worker' | 'member';
  location: {
    city: string;
    country: string;
  };
  church_branch: string;
  createdAt: Date;
  updatedAt: Date;
}
