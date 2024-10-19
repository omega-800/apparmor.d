// apparmor.d - Full set of apparmor profiles
// Copyright (C) 2021-2024 Alexandre Pujol <alexandre@pujol.io>
// SPDX-License-Identifier: GPL-2.0-only

package prepare

import (
	"fmt"
	"regexp"

	"github.com/roddhjav/apparmor.d/pkg/paths"
	"github.com/roddhjav/apparmor.d/pkg/prebuild"
)

type Configure struct {
	prebuild.Base
}

func init() {
	RegisterTask(&Configure{
		Base: prebuild.Base{
			Keyword: "configure",
			Msg:     "Set distribution specificities",
		},
	})
}

func (p Configure) Apply() ([]string, error) {
	res := []string{}

	switch prebuild.Distribution {
	case "arch", "opensuse":

	case "nixos":
		if prebuild.ABI == 3 {
			if err := paths.CopyTo(prebuild.DistDir.Join("nixos"), prebuild.RootApparmord); err != nil {
				return res, err
			}
			path := prebuild.RootApparmord.Join("tunables/multiarch.d/system")
			bytes, err := path.ReadFile()
			if err != nil {
				return res, err
			}
			bytes = regexp.MustCompile(`^@{bin}.*$`).ReplaceAll(bytes, []byte("@{bin}=/{,run/current-system/sw,nix/store/${hex32}*,/home/*/.nix-profile}/{,s}bin,/usr/bin"))
			bytes = regexp.MustCompile(`^@{etc}.*$`).ReplaceAll(bytes, []byte("@{lib}=/{,run/current-system/sw,nix/store/${hex32}*,/home/*/.nix-profile}/{lib,lib64}"))
			path.WriteFile(bytes)
			
		}

	case "ubuntu":
		if err := prebuild.DebianHide.Init(); err != nil {
			return res, err
		}

		if prebuild.ABI == 3 {
			if err := paths.CopyTo(prebuild.DistDir.Join("ubuntu"), prebuild.RootApparmord); err != nil {
				return res, err
			}
		}

	case "debian", "whonix":
		if err := prebuild.DebianHide.Init(); err != nil {
			return res, err
		}

		// Copy Debian specific abstractions
		if err := paths.CopyTo(prebuild.DistDir.Join("ubuntu"), prebuild.RootApparmord); err != nil {
			return res, err
		}

	default:
		return []string{}, fmt.Errorf("%s is not a supported distribution", prebuild.Distribution)

	}
	return res, nil
}
