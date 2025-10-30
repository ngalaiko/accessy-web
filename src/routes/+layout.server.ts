import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ locals, cookies }) => {
	const sessionDataCookie = cookies.get('session_data');
	const sessionData = sessionDataCookie ? JSON.parse(sessionDataCookie) : null;

	return {
		user: locals.user,
		sessionData
	};
};
