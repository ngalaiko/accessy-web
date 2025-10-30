import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { api } from '$lib/api/server';

export const GET: RequestHandler = async ({ request }) => {
	try {
		const authHeader = request.headers.get('authorization');
		if (!authHeader) {
			return json({ error: 'Missing authorization header' }, { status: 401 });
		}

		const authToken = authHeader.replace('Bearer ', '');
		const data = await api.getDoors(authToken);
		return json(data);
	} catch (error) {
		const message = error instanceof Error ? error.message : 'Unknown error';
		return json({ error: message }, { status: 500 });
	}
};
