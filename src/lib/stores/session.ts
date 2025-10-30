import { writable } from 'svelte/store';
import type { SessionData } from '../types';
import { browser } from '$app/environment';

const PRIVATE_KEYS_STORAGE_KEY = 'accessy_private_keys';

interface PrivateKeysStorage {
	login: string;
	signing: string;
}

function createSessionStore() {
	const { subscribe, set, update } = writable<SessionData | null>(null);

	return {
		subscribe,
		set,
		update,
		load: () => {},
		save: async (data: SessionData) => {
			if (!browser) return;
			try {
				const privateKeys: PrivateKeysStorage = {
					login: data.private_keys.login,
					signing: data.private_keys.signing
				};
				localStorage.setItem(PRIVATE_KEYS_STORAGE_KEY, JSON.stringify(privateKeys));

				await fetch('/api/session', {
					method: 'POST',
					headers: { 'Content-Type': 'application/json' },
					body: JSON.stringify({
						auth_token: data.auth_token,
						device_id: data.device_id,
						user_id: data.user_id,
						cert_base64: data.cert_base64,
						phone_number: data.phone_number
					})
				});

				set(data);
			} catch (e) {
				console.error('Failed to save session:', e);
				throw e;
			}
		},
		clear: async () => {
			if (!browser) return;
			try {
				localStorage.removeItem(PRIVATE_KEYS_STORAGE_KEY);

				await fetch('/api/session', {
					method: 'DELETE'
				});

				set(null);
			} catch (e) {
				console.error('Failed to clear session:', e);
			}
		},
		getPrivateKeys: (): PrivateKeysStorage | null => {
			if (!browser) return null;
			try {
				const stored = localStorage.getItem(PRIVATE_KEYS_STORAGE_KEY);
				return stored ? JSON.parse(stored) : null;
			} catch (e) {
				console.error('Failed to load private keys:', e);
				return null;
			}
		}
	};
}

export const session = createSessionStore();
