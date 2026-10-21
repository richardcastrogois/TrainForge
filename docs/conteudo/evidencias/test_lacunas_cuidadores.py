"""Prevent factual fiches from silently becoming executable caregiver content."""
import importlib.util
import copy
import json
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('targeted_caregiver_audit', ROOT / 'auditar-lacunas-cuidadores.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CaregiverExecutionAuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = module.analyse(write=False)
        cls.audit = json.loads((module.FOLDER / 'auditoria-conteudo.json').read_text(encoding='utf-8'))

    def test_all_five_checked_but_only_one_meets_both_gates(self):
        self.assertEqual(self.result['itemsChecked'], 5)
        self.assertEqual(self.result['factualResearchClosedItems'], 5)
        self.assertEqual(self.result['bothResearchGatesMetItems'], ['CG-01'])
        self.assertFalse(self.result['n15GlobalClosed'])

    def test_all_source_fields_and_bodies_are_traceable(self):
        self.assertEqual(self.result['catalogueFieldsChecked'], 90)
        self.assertEqual(self.result['previousSelectedPrimaryBodiesRevalidated'], 28)
        self.assertEqual(self.result['receiptBodiesHashed'], 37)
        self.assertEqual(self.result['nonEmptyNewBodiesHashed'], 8)
        self.assertTrue(all(p['sourcePointersChecked'] for p in self.result['packages']))

    def test_new_rights_pages_are_not_new_clinical_instructions(self):
        self.assertEqual(self.result['newUsableGeneralRightsBodies'], 2)
        self.assertEqual(self.result['newOriginalCaregiverInstructionBodies'], 0)
        self.assertEqual(self.result['newUsableAuxiliaryTechniqueBodies'], 2)
        self.assertEqual(self.result['newUsableMetadataBodies'], 1)
        failed = [x for x in self.result['newReceipts'] if not x['usableBody']]
        self.assertEqual(len(failed), 4)
        self.assertEqual(sorted(x['status'] for x in failed), [403,403,404,404])

    def test_apk_implementation_and_existing_provider_are_not_research_gates(self):
        self.assertTrue(self.audit['definition']['researchDoesNotRequireApkImplementationOrExistingProvider'])
        self.assertTrue(self.audit['definition']['futurePublicationNeedsHumanReviewAndActualRequiredSupport'])
        self.assertTrue(self.audit['items'][0]['executableResearchClosedInDeclaredPath'])

    def test_benson_has_commands_but_no_approved_teaching_asset(self):
        row = self.audit['items'][1]
        self.assertTrue(row['instructionGateMetForDocumentedPath'])
        self.assertFalse(row['useGateMetForDocumentedResearchAssets'])
        self.assertEqual(row['remainingSourceResearch'][0]['id'], 'CG02-MATERIAL')
        self.assertFalse(row['remainingSourceResearch'][0]['resolved'])

    def test_start_context_resolved_only_in_linked_component_scope(self):
        row = self.audit['items'][2]
        context = next(x for x in row['remainingSourceResearch'] if x['id']=='CG03-CONTEXTO')
        self.assertTrue(context['resolved'])
        self.assertFalse(context['wholeProgrammeAudited'])
        self.assertFalse(context['futureCourseApprovalOrStandaloneEfficacy'])
        self.assertFalse(row['useGateMetForDocumentedResearchAssets'])

    def test_revieew_keeps_visual_guidance_distinct_from_complete_commands(self):
        row = self.audit['items'][3]
        self.assertFalse(row['instructionGateMetForDocumentedPath'])
        self.assertTrue(row['useGateMetForDocumentedResearchAssets'])
        self.assertFalse(row['executableResearchClosedInDeclaredPath'])

    def test_pilates_calendar_and_asset_gaps_are_not_filled_by_other_programmes(self):
        row = self.audit['items'][4]
        self.assertFalse(row['instructionGateMetForDocumentedPath'])
        self.assertFalse(row['useGateMetForDocumentedResearchAssets'])
        self.assertEqual(len(row['remainingSourceResearch']), 3)
        self.assertTrue(all(not x['resolved'] for x in row['remainingSourceResearch']))

    def test_query_exposes_execution_audit_separately_from_factual_flag(self):
        result = module.CATALOGUE.validate()
        self.assertTrue(result['executionAuditChecked'])
        self.assertEqual(result['executableResearchClosedItems'], 1)
        item = result['resolvedItems'][4]
        self.assertTrue(item['researchItemClosed'])
        self.assertFalse(item['executionContentAudit']['item']['executableResearchClosedInDeclaredPath'])
        self.assertFalse(item['releaseApproved'])

    def test_publication_can_never_be_inferred_from_executable_research(self):
        self.assertFalse(self.audit['releaseApproved'])
        self.assertFalse(self.audit['appImplemented'])
        self.assertFalse(self.result['mechanicalChecksAreClinicalOrLegalApproval'])
        self.assertFalse(self.result['n21Allowed'])

    def test_missing_instruction_or_use_condition_cannot_be_hidden_in_factual_closed_flag(self):
        data = module.CATALOGUE.load_catalogue()
        data['items'][0]['sourceId'] = 'WRONG'
        with self.assertRaisesRegex(ValueError,'different programme'):
            module.CATALOGUE.validate(data)

    def test_auxiliary_dose_pain_and_photos_are_not_transferred(self):
        comparison = json.loads((module.FOLDER / 'cotejo-g4.json').read_text(encoding='utf-8'))
        self.assertEqual(comparison['verificationLimits']['configurationCandidates'], 5)
        self.assertEqual(comparison['verificationLimits']['fullOriginalVariantGuidesClosed'], 0)
        self.assertFalse(comparison['prescriptionController']['nhsHoldsRepetitionsSetsOrPainProgressionImported'])
        self.assertFalse(comparison['prescriptionController']['newWarmupCooldownOrCalendarCreated'])
        self.assertFalse(comparison['rights']['originalSi2LicenceCopiedToNhs'])
        self.assertTrue(all(not row['fullVariantGuideApproved'] for row in comparison['configurationCandidates']))

    def test_captcha_404_is_not_pdf_absence_and_empty_error_is_not_usable(self):
        challenge = next(x for x in self.result['newReceipts'] if x['id']=='n15dir-cg04-tese-canonica-html')
        self.assertEqual(challenge['status'], 404)
        self.assertTrue(challenge['securityChallengeReceived'])
        self.assertFalse(challenge['usableBody'])
        empty = [x for x in self.result['newReceipts'] if x['bytes']==0]
        self.assertEqual(len(empty), 1)
        self.assertFalse(empty[0]['usableBody'])

    def test_current_queue_is_not_completed_by_the_old_factual_sequence(self):
        queue = json.loads((ROOT.parent / 'fila-cuidadores.json').read_text(encoding='utf-8'))
        self.assertIsNone(queue['currentUserFocusCompleted'])
        sequence = queue['executionSequence']
        self.assertEqual(sequence['closedItems'], self.result['bothResearchGatesMetItems'])
        self.assertEqual(sequence['activeItem'], 'CG-02')
        self.assertEqual(sequence['pendingSourceQuestions'], self.result['sourceQuestionsStillPending'])
        self.assertFalse(sequence['allFiveExecutableResearchClosed'])
        self.assertFalse(queue['n21Started'])

    def _query_with_audit(self, changed):
        audit_path = (module.FOLDER / 'auditoria-conteudo.json').resolve()
        original_read = Path.read_text

        def read(path, *args, **kwargs):
            if path.resolve() == audit_path:
                return json.dumps(changed)
            return original_read(path, *args, **kwargs)

        with patch.object(Path, 'read_text', new=read):
            return module.CATALOGUE.validate()

    def test_query_rejects_extra_execution_rows_instead_of_inflating_closed_count(self):
        changed = copy.deepcopy(self.audit)
        extra = copy.deepcopy(changed['items'][0])
        extra['id'] = 'CG-UNREQUESTED'
        changed['items'].append(extra)
        with self.assertRaisesRegex(ValueError, 'exactly the catalogue'):
            self._query_with_audit(changed)

    def test_query_rejects_publication_flag_and_unresolved_closed_item(self):
        changed = copy.deepcopy(self.audit)
        changed['items'][0]['releaseApproved'] = True
        with self.assertRaisesRegex(ValueError, 'cannot approve publication'):
            self._query_with_audit(changed)
        changed['items'][0]['releaseApproved'] = False
        changed['items'][0]['remainingSourceResearch'].append({'id':'UNRESOLVED','resolved':False})
        with self.assertRaisesRegex(ValueError, 'unresolved source questions'):
            self._query_with_audit(changed)


if __name__ == '__main__':
    unittest.main()
