import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { api } from '$lib/api/server';

export const POST: RequestHandler = async ({ request }) => {
	try {
		const { code, id } = await request.json();
		const data = await api.submitVerificationCode({ code, id });
		return json(data);
	} catch (error) {
		const message = error instanceof Error ? error.message : 'Unknown error';
		return json({ error: message }, { status: 500 });
	}
};
