import type { PageServerLoad } from './$types';
import { redirect } from '@sveltejs/kit';

export const load: PageServerLoad = async ({ locals, fetch }) => {
	if (!locals.user) {
		throw redirect(302, '/');
	}

	try {
		// Fetch doors from API using server-side fetch
		const response = await fetch('/api/accessy/org/client-context/mobile', {
			headers: {
				Authorization: `Bearer ${locals.user.auth_token}`
			}
		});

		if (!response.ok) {
			throw new Error('Failed to fetch doors');
		}

		const data = await response.json();
		const publications = data.mostInvokedPublicationsList || [];

		return {
			publications
		};
	} catch (e) {
		console.error('Error loading doors:', e);
		throw redirect(302, '/');
	}
};
