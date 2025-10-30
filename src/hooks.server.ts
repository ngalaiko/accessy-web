import type { Handle } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';

const handleAuth: Handle = async ({ event, resolve }) => {
	// Get auth token from cookie
	const authToken = event.cookies.get('auth_token');
	const certBase64 = event.cookies.get('cert_base64');
	const deviceId = event.cookies.get('device_id');
	const userId = event.cookies.get('user_id');

	// Set locals for use in load functions
	event.locals.user = authToken
		? {
				auth_token: authToken,
				cert_base64: certBase64 || '',
				device_id: deviceId || '',
				user_id: userId || ''
			}
		: null;

	return resolve(event);
};

export const handle = sequence(handleAuth);
