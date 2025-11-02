import type { PageServerLoad } from './$types';
import { redirect } from '@sveltejs/kit';

export const load: PageServerLoad = async ({ locals }) => {
	// If already logged in, redirect to doors
	if (locals.user) {
		throw redirect(302, '/doors');
	}

	return {};
};
