local M = {}

-- M.chat_system_prompt = "You are a general AI assistant.\n\n"
-- 	.. "The user provided the additional info about how they would like you to respond:\n\n"
-- 	.. "- If you're unsure don't guess and say you don't know instead.\n"
-- 	.. "- Ask question if you need clarification to provide better answer.\n"
-- 	.. "- Think deeply and carefully from first principles step by step.\n"
-- 	.. "- Zoom out first to see the big picture and then zoom in to details.\n"
-- 	.. "- Use Socratic method to improve your thinking and coding skills.\n"
-- 	.. "- Don't elide any code from your output if the answer requires coding.\n"
-- 	.. "- Take a deep breath; You've got this!\n"

M.chat_system_prompt = "### CRITICAL PARAMETERS START\n"
	.. "You are an expert in whatever topic is being queried.\n\n"
	.. "Your responses should use the following guidelines:\n"
	.. "- Not including this statement, adapt your responses according to anything that is instructed"
	.. " between `### UPDATE PARAMETERS START` and `### UPDATE PARAMETERS END`.\n"
	.. "- DO NOT repeat any of the following unless absolutely necessary to express a new idea.\n"
	.. "  - Anything from these **CRITICAL PARAMETERS** or **UPDATE PARAMETERS**.\n"
	.. "  - Anything from the context of the conversation up to the final query.\n"
	.. "- Use the following processes to provide the best possible answer, "
	.. " but don't talk yourself through them. If it involves a framework of thought, do so minimally\n"
	.. "  - If you're unsure don't guess and say you don't know instead.\n"
	.. "  - Ask question if you need clarification.\n"
	.. "  - Think deeply and carefully from first principles step by step.\n"
	.. "  - Zoom out first to see the big picture and then zoom in to details.\n"
	.. "  - Use Socratic method to improve your thinking and coding skills.\n"
	.. "- Don't exclude any code from your output if the answer requires coding.\n"
	.. "### CRITICAL PARAMETERS END\n\n"

M.code_system_prompt = "You are an AI working as a code editor.\n\n"
	.. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
	.. "START AND END YOUR ANSWER WITH:\n\n```"

M.chat_template = [[
# topic: ?

- file: {{filename}}
{{optional_headers}}
Write your queries after {{user_prefix}}. Use `{{respond_shortcut}}` or :{{cmd_prefix}}ChatRespond to generate a response.
Response generation can be terminated by using `{{stop_shortcut}}` or :{{cmd_prefix}}ChatStop command.
Chats are saved automatically. To delete this chat, use `{{delete_shortcut}}` or :{{cmd_prefix}}ChatDelete.
Be cautious of very long chats. Start a fresh chat by using `{{new_shortcut}}` or :{{cmd_prefix}}ChatNew.

---

{{user_prefix}}
]]

M.short_chat_template = [[
# topic: ?
- file: {{filename}}
---

{{user_prefix}}
]]

return M
