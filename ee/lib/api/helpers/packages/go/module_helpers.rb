# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Go
        module ModuleHelpers
          def case_encode(str)
            # Converts "github.com/Azure" to "github.com/!azure"
            #
            # From `go help goproxy`:
            #
            # > To avoid problems when serving from case-sensitive file systems,
            # > the <module> and <version> elements are case-encoded, replacing
            # > every uppercase letter with an exclamation mark followed by the
            # > corresponding lower-case letter: github.com/Azure encodes as
            # > github.com/!azure.

            str.gsub(/A-Z/) { |s| "!#{s.downcase}"}
          end

          def case_decode(str)
            # Converts "github.com/!azure" to "github.com/Azure"
            #
            # See #case_encode

            str.gsub(/![[:alpha:]]/) { |s| s[1..].upcase }
          end

          def semver?(tag)
            return false if tag.dereferenced_target.nil?

            ::Packages::SemVer.match?(tag.name, prefixed: true)
          end

          def pseudo_version?(version)
            return false unless version

            if version.is_a? String
              version = parse_semver version
              return false unless version
            end

            pre = version.prerelease

            # Valid pseudo-versions are:
            #   vX.0.0-yyyymmddhhmmss-sha1337beef0, when no earlier tagged commit exists for X
            #   vX.Y.Z-pre.0.yyyymmddhhmmss-sha1337beef0, when most recent prior tag is vX.Y.Z-pre
            #   vX.Y.(Z+1)-0.yyyymmddhhmmss-sha1337beef0, when most recent prior tag is vX.Y.Z

            if version.minor != 0 || version.patch != 0
              m = /\A(.*\.)?0\./.freeze.match pre
              return false unless m

              pre = pre[m[0].length..]
            end

            # This pattern is intentionally more forgiving than the patterns
            # above. Correctness is verified by #pseudo_version_commit.
            /\A\d{14}-\h+\z/.freeze.match? pre
          end

          def pseudo_version_commit(project, semver)
            # Per Go's implementation of pseudo-versions, a tag should be
            # considered a pseudo-version if it matches one of the patterns
            # listed in #pseudo_version?, regardless of the content of the
            # timestamp or the length of the SHA fragment. However, an error
            # should be returned if the timestamp is not correct or if the SHA
            # fragment is not exactly 12 characters long. See also Go's
            # implementation of:
            #
            # - [*codeRepo.validatePseudoVersion](https://github.com/golang/go/blob/daf70d6c1688a1ba1699c933b3c3f04d6f2f73d9/src/cmd/go/internal/modfetch/coderepo.go#L530)
            # - [Pseudo-version parsing](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/pseudo.go)
            # - [Pseudo-version request processing](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/coderepo.go)

            # Go ignores anything before '.' or after the second '-', so we will do the same
            timestamp, sha = semver.prerelease.split('-').last 2
            timestamp = timestamp.split('.').last
            commit = project.repository.commit_by(oid: sha)

            # Error messages are based on the responses of proxy.golang.org

            # Verify that the SHA fragment references a commit
            raise ArgumentError.new 'invalid pseudo-version: unknown commit' unless commit

            # Require the SHA fragment to be 12 characters long
            raise ArgumentError.new 'invalid pseudo-version: revision is shorter than canonical' unless sha.length == 12

            # Require the timestamp to match that of the commit
            raise ArgumentError.new 'invalid pseudo-version: does not match version-control timestamp' unless commit.committed_date.strftime('%Y%m%d%H%M%S') == timestamp

            commit
          end

          def parse_semver(str)
            ::Packages::SemVer.parse(str, prefixed: true)
          end
        end
      end
    end
  end
end
