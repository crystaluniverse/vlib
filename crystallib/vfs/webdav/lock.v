module webdav

import time
import rand

struct Lock {
	resource   string
	owner      string
	token      string
	depth      int // 0 for a single resource, 1 for recursive
	timeout    int // in seconds
	created_at time.Time
}

struct LockManager {
mut:
	locks map[string]Lock
}

pub fn (mut lm LockManager) lock(resource string, owner string, depth int, timeout int) !string {
	if resource in lm.locks {
		// Check if the lock is still valid
		existing_lock := lm.locks[resource]
		if time.now().unix() - existing_lock.created_at.unix() < existing_lock.timeout {
			return existing_lock.token // Resource is already locked
		}
		// Expired lock, remove it
		lm.unlock(resource)
	}

	// Generate a new lock token
	token := rand.uuid_v4()
	lm.locks[resource] = Lock{
		resource:   resource
		owner:      owner
		token:      token
		depth:      depth
		timeout:    timeout
		created_at: time.now()
	}
	return token
}

pub fn (mut lm LockManager) unlock(resource string) bool {
	if resource in lm.locks {
		lm.locks.delete(resource)
		return true
	}
	return false
}

pub fn (lm LockManager) is_locked(resource string) bool {
	if resource in lm.locks {
		lock_ := lm.locks[resource]
		// Check if lock is expired
		if time.now().unix() - lock_.created_at.unix() >= lock_.timeout {
			return false
		}
		return true
	}
	return false
}

pub fn (mut lm LockManager) unlock_with_token(resource string, token string) bool {
	if resource in lm.locks {
		lock_ := lm.locks[resource]
		if lock_.token == token {
			lm.locks.delete(resource)
			return true
		}
	}
	return false
}

fn (mut lm LockManager) lock_recursive(resource string, owner string, depth int, timeout int) !string {
	if depth == 0 {
		return lm.lock(resource, owner, depth, timeout)
	}
	// Implement logic to lock child resources if depth == 1
	return ''
}

pub fn (mut lm LockManager) cleanup_expired_locks() {
	// now := time.now().unix()
	// lm.locks
	// lm.locks = lm.locks.filter(it.value.created_at.unix() + it.value.timeout > now)
}
