import { Injectable } from '@angular/core';
import {
  Auth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  user,
} from '@angular/fire/auth';
import { Firestore, doc, getDoc, setDoc } from '@angular/fire/firestore';
import { User } from '../models/user.model';
import { Observable, from, map, switchMap } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  // Observable that will emit the current user's data
  user$: Observable<User | null>;
  constructor(private auth: Auth, private firestore: Firestore) {
    // Initialize the user$ observable
    this.user$ = user(this.auth).pipe(
      switchMap((firebaseUser) =>
        // If there's a logged-in user, fetch their data from Firestore
        // Otherwise, emit null
        firebaseUser ? this.getUserData(firebaseUser.uid) : from([null])
      )
    );
  }

  private getUserData(uid: string): Observable<User | null> {
    const userDocRef = doc(this.firestore, `users/${uid}`);
    return from(getDoc(userDocRef)).pipe(
      map((docSnap) => (docSnap.exists() ? (docSnap.data() as User) : null))
    );
  }
}
