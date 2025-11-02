import type { LayoutLoad } from './$types';
import { session } from '$lib/stores/session';
import { browser } from '$app/environment';

export const ssr = true;

export const load: LayoutLoad = async ({ data }) => {
	if (browser && data.user && data.sessionData) {
		const privateKeys = session.getPrivateKeys();
		if (privateKeys) {
			session.set({
				auth_token: data.user.auth_token,
				device_id: data.user.device_id,
				user_id: data.user.user_id,
				cert_base64: data.user.cert_base64,
				phone_number: data.sessionData.phone_number,
				private_keys: privateKeys
			});
		}
	}

	return data;
};
