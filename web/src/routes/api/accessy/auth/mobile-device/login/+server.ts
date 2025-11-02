import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { api } from '$lib/api/server';

export const POST: RequestHandler = async ({ request }) => {
	try {
		// Login proof is sent as text/plain, not JSON (per Python implementation)
		const loginProof = await request.text();
		const data = await api.login({ loginProof });
		return json(data);
	} catch (error) {
		const message = error instanceof Error ? error.message : 'Unknown error';
		return json({ error: message }, { status: 500 });
	}
};
