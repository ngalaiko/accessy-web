import { writable } from 'svelte/store';
import type { SessionData } from '../types';
import { browser } from '$app/environment';

const STORAGE_KEY = 'accessy_session';

function createSessionStore() {
	const { subscribe, set, update } = writable<SessionData | null>(null);

	return {
		subscribe,
		set,
		update,
		load: () => {
			if (!browser) return;
			try {
				const stored = localStorage.getItem(STORAGE_KEY);
				if (stored) {
					const data = JSON.parse(stored);
					set(data);
				}
			} catch (e) {
				console.error('Failed to load session:', e);
			}
		},
		save: (data: SessionData) => {
			if (!browser) return;
			try {
				localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
				set(data);
			} catch (e) {
				console.error('Failed to save session:', e);
			}
		},
		clear: () => {
			if (!browser) return;
			try {
				localStorage.removeItem(STORAGE_KEY);
				set(null);
			} catch (e) {
				console.error('Failed to clear session:', e);
			}
		}
	};
}

export const session = createSessionStore();
