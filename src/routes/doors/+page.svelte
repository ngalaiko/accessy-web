<script lang="ts">
	import type { PageData } from './$types';
	import { session } from '$lib/stores/session';
	import type { Door } from '$lib/types';
	import * as api from '$lib/api-client';

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
			{#each doors as door, i (door.publication_id)}
				{#if door.operations.length > 0}
					<button
						class="door-button"
						class:unlocking={unlocking === door.operations[0].id}
						onclick={() => handleUnlock(door)}
						disabled={unlocking === door.operations[0].id}
						style="animation-delay: {i * 0.05}s"
					>
						<div class="door-name">
							{door.favorite ? '★ ' : ''}{door.name}
						</div>
						{#if unlocking === door.operations[0].id}
							<div class="status-text">Unlocking...</div>
						{/if}
					</button>
				{:else}
					<div class="door-button disabled" style="animation-delay: {i * 0.05}s">
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
		box-sizing: border-box;
	}

	.door-grid {
		display: flex;
		flex-wrap: wrap;
		gap: 1rem;
		justify-content: flex-start;
	}

	@keyframes fadeInUp {
		from {
			opacity: 0;
			transform: translateY(20px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	@keyframes pulse {
		0%,
		100% {
			transform: scale(1);
		}
		50% {
			transform: scale(0.95);
		}
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
		border: none;
		border-radius: 8px;
		cursor: pointer;
		font-size: 1rem;
		min-height: 150px;
		flex: 1 1 200px;
		min-width: 200px;
		max-width: 300px;
		box-sizing: border-box;
		transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
		animation: fadeInUp 0.5s ease-out backwards;
	}

	@media (max-width: 768px) {
		.door-button {
			flex: 1 1 calc(50% - 0.5rem);
			min-width: 0;
			max-width: none;
		}
	}

	@media (max-width: 480px) {
		.door-button {
			flex: 1 1 100%;
		}
	}

	.door-button:hover:not(:disabled):not(.disabled) {
		background: #333;
		transform: translateY(-4px) scale(1.02);
		box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
	}

	.door-button:active:not(:disabled):not(.disabled) {
		transform: translateY(-2px) scale(1);
	}

	.door-button.unlocking {
		animation: pulse 1s ease-in-out infinite !important;
	}

	.door-button:disabled {
		background: #999;
		cursor: not-allowed;
	}

	.door-button.disabled {
		background: #ccc;
		color: #666;
		cursor: not-allowed;
	}

	.door-name {
		font-weight: bold;
		font-size: 1.125rem;
		text-align: center;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.status-text {
		font-size: 0.875rem;
		opacity: 0.8;
		text-align: center;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.error {
		color: #c00;
		margin: 1rem 0;
	}

	@media (max-width: 480px) {
		.door-button {
			min-height: 120px;
			padding: 1.5rem 1rem;
		}

		.door-name {
			font-size: 1rem;
		}
	}
</style>
