module luadns

import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.develop.gittools

// returns the directory of the git repository for the dns
pub fn (dns LuaDNS) directory() !pathlib.Path {
	mut gs := gittools.new()!
	mut repo := gs.get_repo(url: dns.url, pull: true)!
	repo_path := repo.get_path()!
	return pathlib.get_dir(path: repo_path)!
}

pub fn (dns LuaDNS) domain_file(domain string) !pathlib.Path {
	return pathlib.get_file(path: '${dns.directory()!.path}/${domain}.lua')!
}

// returns the git repository for the dns
pub fn (dns LuaDNS) repository() !&gittools.GitRepo {
	mut gs := gittools.new()!
	repo := gs.get_repo(url: dns.url, pull: true)!
	return repo
}

pub fn (mut dns LuaDNS) set_domain(domain string, ip string) ! {
	// Validate the IP address
	if !is_valid_ip(ip) {
		return error('Invalid IP address: ${ip}')
	}

	// Validate the domain
	if !is_valid_domain(domain) {
		return error('Invalid domain: ${domain}')
	}

	subdomain := if domain.contains('.') { domain.all_before('.') } else { domain }
	root_domain := if domain.contains('.') { domain.all_after('.') } else { domain }

	mut config := dns.find_or_create_config(root_domain)

	mut updated := false
	for mut record in config.a_records {
		if record.name == subdomain {
			record.ip = ip
			updated = true
			break
		}
	}
	if !updated {
		if subdomain == root_domain {
			config.a_records << ARecord{'', ip}
		} else {
			config.a_records << ARecord{subdomain, ip}
		}
	}

	// Add default CNAME and CAA records if they do not exist
	if config.cname_records.len == 0 {
		config.cname_records << CNAMERecord{'www', '@'}
	}

	if config.caa_records.len == 0 {
		config.caa_records << CAARecord{'', 'letsencrypt.org', 'issue'}
		config.caa_records << CAARecord{'', 'mailto:info@threefold.io', 'iodef'}
	}

	dns.save_config(config)!
}

fn (mut dns LuaDNS) find_or_create_config(domain string) DNSConfig {
	for mut config in dns.configs {
		if config.domain == domain {
			return config
		}
	}
	dns.configs << DNSConfig{
		domain: domain
	}
	return dns.configs[dns.configs.len - 1]
}

fn (dns LuaDNS) save_config(config DNSConfig) ! {
	mut repo := dns.repository()!
	repo.pull()!

	mut file := pathlib.get_file(path: '${dns.directory()!.path}/${config.domain}.lua')!

	mut content := ''

	for record in config.a_records {
		if record.name == '' || record.name == '_a' {
			content += 'a(_a, "${record.ip}")\n'
		} else {
			content += 'a("${record.name}", "${record.ip}")\n'
		}
	}

	for record in config.cname_records {
		if record.alias == '_a' {
			content += 'cname("${record.name}", _a)\n'
		} else {
			content += 'cname("${record.name}", "${record.alias}")\n'
		}
	}

	for record in config.caa_records {
		content += 'caa("${record.name}", "${record.value}", "${record.tag}")\n'
	}

	file.write(content)!
	repo.commit(msg: 'Update DNS records')!
	repo.pull()!
	repo.push()!
}
