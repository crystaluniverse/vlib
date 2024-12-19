module rpcsocket

import freeflowuniverse.crystallib.data.ourtime

// Params for finding agents
pub struct AgentFindParams {
pub mut:
	id           ?u32
	name         ?string
	ipaddr       ?string
	location     ?string
	pubkey       ?string
}

// Manager for Agent objects
pub struct AgentManager {
mut:
	agents map[u32]Agent
	last_id u32
}

// Create a new agent manager
pub fn new_agent_manager() AgentManager {
	return AgentManager{
		agents: map[u32]Agent{}
		last_id: 0
	}
}

// Set (create/update) an agent
pub fn (mut m AgentManager) set(mut agent Agent) !Agent {
	if agent.id == 0 {
		// New agent
		m.last_id++
		agent.id = m.last_id
		agent.create_date = ourtime.now()
	}
	m.agents[agent.id] = agent
	return agent
}

// Get an agent by ID
pub fn (m AgentManager) get(id u32) !Agent {
	if id in m.agents {
		return m.agents[id]
	}
	return error('Agent with ID ${id} not found')
}

// Delete an agent by ID
pub fn (mut m AgentManager) delete(id u32) ! {
	if id in m.agents {
		m.agents.delete(id)
		return
	}
	return error('Agent with ID ${id} not found')
}

// Delete all agents
pub fn (mut m AgentManager) delete_all() {
	m.agents.clear()
	m.last_id = 0
}

// Find agents based on parameters
pub fn (m AgentManager) find(params AgentFindParams) []Agent {
	mut result := []Agent{}
	
	for _, agent in m.agents {
		if !matches_agent_params(agent, params) {
			continue
		}
		result << agent
	}
	
	return result
}

// Helper function to check if an agent matches the find parameters
fn matches_agent_params(agent Agent, params AgentFindParams) bool {
	if params.id != none && params.id != agent.id {
		return false
	}
	if params.name != none && params.name != agent.name {
		return false
	}
	if params.ipaddr != none && params.ipaddr != agent.ipaddr {
		return false
	}
	if params.location != none && params.location != agent.location {
		return false
	}
	if params.pubkey != none && params.pubkey != agent.pubkey {
		return false
	}
	return true
}
