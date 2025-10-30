import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { api } from '$lib/api/server';

export const PUT: RequestHandler = async ({ request, params }) => {
	try {
		const { operationId } = params;
		const authHeader = request.headers.get('authorization');
		const proof = request.headers.get('x-axs-proof');

		if (!authHeader) {
			return json({ error: 'Missing authorization header' }, { status: 401 });
		}

		if (!proof) {
			return json({ error: 'Missing x-axs-proof header' }, { status: 401 });
		}

		const authToken = authHeader.replace('Bearer ', '');
		const data = await api.unlockDoor({ operationId, proof }, authToken);
		return json(data);
	} catch (error) {
		const message = error instanceof Error ? error.message : 'Unknown error';
		return json({ error: message }, { status: 500 });
	}
};
