import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { api } from '$lib/api/server';

export const POST: RequestHandler = async ({ request }) => {
	try {
		const { msisdn } = await request.json();
		const data = await api.requestVerification({ msisdn });
		return json(data);
	} catch (error) {
		const message = error instanceof Error ? error.message : 'Unknown error';
		return json({ error: message }, { status: 500 });
	}
};
