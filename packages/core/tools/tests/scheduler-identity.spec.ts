import { expect, it, vi } from 'vitest'
import { Context } from '@deepseek-ai/cordis'
import { ToolCallId } from '@deepseek-ai/dsh-llm'
import SystemPrompt from '@deepseek-ai/dsh-system-prompt'
import ToolRuntime from '@deepseek-ai/dsh-tools'

it('prepares calls on an existing service from a separately loaded module', async () => {
  const ctx = new Context()
  try {
    await ctx.plugin(SystemPrompt)
    await ctx.plugin(ToolRuntime)
    vi.resetModules()
    const reloaded = await import('@deepseek-ai/dsh-tools')
    const scheduler = ctx.tools[reloaded.TOOL_RUNTIME_SCHEDULER]
    const prepared = await scheduler.prepare({
      signal: new AbortController().signal,
      callId: ToolCallId('separate-module'),
      name: 'missing',
      arguments: {},
    })
    expect(prepared.kind).toBe('dispatch')
    const result = await scheduler.dispatch(prepared.exec)
    expect(result).toMatchObject({
      kind: 'post-result',
      result: { isError: true, error: { info: { code: 'UNKNOWN_TOOL' } } },
    })
  } finally {
    await ctx.fiber.dispose()
    vi.resetModules()
  }
})
