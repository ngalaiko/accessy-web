<script lang="ts">
	import type { PageData } from './$types';
	import { session } from '$lib/stores/session';
	import * as api from '$lib/api-client';
	import type { Door } from '$lib/api/types';

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
	let doors: Door[] = $state(data.doors);
	let privateKeys = $state(data.privateKeys);
	let error = $state('');
	let unlocking = $state('');

	async function handleUnlock(door: Door) {
		if (!$session || !privateKeys) {
			error = 'Not authenticated';
			return;
		}

		if (door.operations.length === 0) {
			error = 'No operations available for this door';
			return;
		}

		const operation = door.operations[0];
		unlocking = operation.id;
		error = '';

		try {
			await api.unlockDoor(
				operation.id,
				$session.auth_token,
				$session.cert_base64,
				privateKeys.login
			);
			// Success feedback
			setTimeout(() => {
				unlocking = '';
			}, 1500);
		} catch (e) {
			error = `Failed to unlock ${door.name}: ${e instanceof Error ? e.message : 'Unknown error'}`;
			unlocking = '';
		}
	}
</script>

<div class="doors-page">
	{#if error}
		<p class="error">{error}</p>
	{/if}

	{#if doors.length === 0}
		<p>No doors available</p>
	{:else}
		<div class="door-grid">
			{#each doors as door (door.publication_id)}
				{#if door.operations.length > 0}
					<button
						class="door-button"
						class:unlocking={unlocking === door.operations[0].id}
						onclick={() => handleUnlock(door)}
						disabled={unlocking === door.operations[0].id}
					>
						<div class="door-name">
							{door.name}
						</div>
						{#if unlocking === door.operations[0].id}
							<div class="status-text">Unlocking...</div>
						{/if}
					</button>
				{:else}
					<div class="door-button disabled">
						<div class="door-name">{door.name}</div>
					</div>
				{/if}
			{/each}
		</div>
	{/if}
</div>

<style>
	.doors-page {
		display: flex;
		flex-direction: column;
		width: 100%;
		max-width: 100%;
	}

	.door-grid {
		display: flex;
		flex-wrap: wrap;
		gap: 1rem;
		justify-content: flex-start;
		width: 100%;
		max-width: 100%;
	}

	.door-button {
		display: flex;
		flex-direction: column;
		justify-content: center;
		align-items: center;
		gap: 0.5rem;
		padding: 2rem 1rem;
		background: #000;
		color: #fff;
		border: 4px solid #000;
		cursor: pointer;
		font-size: 1rem;
		min-height: 120px;
		flex: 1 1 calc(50% - 0.5rem);
		min-width: 0;
		max-width: 100%;
		font-family: monospace;
		text-transform: uppercase;
	}

	@media (min-width: 769px) {
		.door-button {
			flex: 1 1 200px;
			min-width: 200px;
			max-width: 300px;
			min-height: 150px;
		}
	}

	@media (max-width: 480px) {
		.door-button {
			flex: 1 1 100%;
			padding: 1.5rem 1rem;
			min-height: 100px;
		}
	}

	.door-button:disabled {
		background: #fff;
		color: #000;
		cursor: not-allowed;
		border: 4px solid #000;
	}

	.door-button.disabled {
		background: #fff;
		color: #000;
		cursor: not-allowed;
		border: 4px solid #000;
	}

	.door-name {
		font-weight: bold;
		font-size: 1rem;
		text-align: center;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.status-text {
		font-size: 0.875rem;
		text-align: center;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.error {
		color: #fff;
		background: #000;
		border: 2px solid #000;
		padding: 0.5rem;
		margin: 1rem 0;
		font-family: monospace;
	}
</style>
