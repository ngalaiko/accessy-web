import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';

export const POST: RequestHandler = async ({ request, cookies }) => {
	const data = await request.json();
	cookies.set('auth_token', data.auth_token, {
		path: '/',
		httpOnly: true,
		secure: true,
		sameSite: 'strict',
		maxAge: 60 * 60 * 24 * 30
	});

	cookies.set('cert_base64', data.cert_base64, {
		path: '/',
		httpOnly: true,
		secure: true,
		sameSite: 'strict',
		maxAge: 60 * 60 * 24 * 30
	});

	cookies.set('device_id', data.device_id, {
		path: '/',
		httpOnly: true,
		secure: true,
		sameSite: 'strict',
		maxAge: 60 * 60 * 24 * 30
	});

	cookies.set('user_id', data.user_id, {
		path: '/',
		httpOnly: true,
		secure: true,
		sameSite: 'strict',
		maxAge: 60 * 60 * 24 * 30
	});

	cookies.set('session_data', JSON.stringify({
		phone_number: data.phone_number
	}), {
		path: '/',
		httpOnly: false,
		secure: true,
		sameSite: 'strict',
		maxAge: 60 * 60 * 24 * 30
	});

	return json({ success: true });
};

export const DELETE: RequestHandler = async ({ cookies }) => {
	cookies.delete('auth_token', { path: '/' });
	cookies.delete('cert_base64', { path: '/' });
	cookies.delete('device_id', { path: '/' });
	cookies.delete('user_id', { path: '/' });
	cookies.delete('session_data', { path: '/' });

	return json({ success: true });
};
