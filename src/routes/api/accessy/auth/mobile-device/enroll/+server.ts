import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { api } from '$lib/api/server';

export const POST: RequestHandler = async ({ request }) => {
	try {
		const { deviceName, recoveryKey, csrForSigning, csrForLogin } = await request.json();

		// Extract enrollToken from Authorization header (format: "Bearer {token}")
		const authHeader = request.headers.get('authorization');
		if (!authHeader || !authHeader.startsWith('Bearer ')) {
			return json({ error: 'Missing or invalid authorization header' }, { status: 401 });
		}
		const enrollToken = authHeader.substring(7); // Remove "Bearer " prefix

		const data = await api.enrollDevice(
			{
				deviceName,
				recoveryKey,
				csrForSigning,
				csrForLogin,
				appName: 'Accessy-iOS'
			},
			enrollToken
		);

		return json(data);
	} catch (error) {
		const message = error instanceof Error ? error.message : 'Unknown error';
		return json({ error: message }, { status: 500 });
	}
};
