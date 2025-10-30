import type { PageLoad } from './$types';
import { get } from 'svelte/store';
import { session } from '$lib/stores/session';
import * as api from '$lib/api-client';
import type { Door } from '$lib/types';

export const ssr = false;

export const load: PageLoad = async ({ data }) => {
	const $session = get(session);

	if (!$session) {
		throw new Error('No session available');
	}

	const privateKeys = await api.loadSessionKeys($session);

	interface Publication {
		id: string;
		name: string;
		asset?: {
			id: string;
			name: string;
			operations?: Array<{ id: string; name: string }>;
		};
		favorite?: boolean;
	}

	const doors: Door[] = (data.publications as Publication[])
		.filter((pub) => pub && typeof pub === 'object')
		.map((pub) => {
			const asset = pub.asset || { id: '', name: '', operations: [] };
			const operations = Array.isArray(asset.operations) ? asset.operations : [];

			return {
				publication_id: pub.id,
				name: pub.name || 'Unnamed',
				asset_id: asset.id,
				asset_name: asset.name,
				operations,
				favorite: pub.favorite || false
			};
		})
		.sort((a, b) => a.name.localeCompare(b.name));

	return {
		doors,
		privateKeys
	};
};
