import unittest
from catalog_rollout_ci import check_rollout_service
class RolloutServiceBoundary(unittest.TestCase):
 def test_container_must_be_explicit_and_no_foreign_context(self):
  env={'TF_CATALOG_PG_CONTAINER':'a'*64};check_rollout_service(env)
  for change in [{'TF_CATALOG_PG_CONTAINER':'evaluation'},{'TF_CATALOG_PG_CONTAINER':'a'*64+'; x'},{'DOCKER_HOST':'remote.invalid'},{'DOCKER_CONTEXT':'other'}]:
   with self.subTest(change=change),self.assertRaises(RuntimeError):check_rollout_service(dict(env,**change))
