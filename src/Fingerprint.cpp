/*
 *
 * (C) 2013-19 - ntop.org
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 */

#include "ntop_includes.h"

/* *************************************** */

void Fingerprint::update(char *_fprint, char *app_name) {
  std::string fprint(_fprint);
  std::map<std::string, FingerprintStats>::iterator it = fp.find(fprint);

  if(it == fp.end()) {
    FingerprintStats s;

    prune();
    s.app_name = std::string(app_name), s.num_uses = 1;
    fp[fprint] = s;
  } else {
    it->second.num_uses++, it->second.app_name = std::string(app_name);
  }
}

/* *************************************** */

void Fingerprint::lua(const char *key, lua_State* vm) {
  lua_newtable(vm);
  
  for(std::map<std::string, FingerprintStats>::iterator it = fp.begin(); it != fp.end(); ++it)
    lua_push_int32_table_entry(vm, it->first.c_str(),
			       it->second.num_uses); // TODO: export app_name when filled

  lua_pushstring(vm, key);
  lua_insert(vm, -2);
  lua_settable(vm, -3);  
}

/* *************************************** */

void Fingerprint::prune() {
  if(fp.size() > MAX_NUM_FINGERPRINT) {
    std::map<std::string, FingerprintStats>::iterator it = fp.begin();

    while(it != fp.end()) {
      if(it->second.num_uses < 3)
	it = fp.erase(it);
      else
	++it;
    }
  }
}
