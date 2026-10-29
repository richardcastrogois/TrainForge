"""Runtime grants shared by the owned local cluster and disposable CI fixtures."""


def runtime_statements(*, training=False, meals=False):
    readonly = ['sources','content_versions','content_withdrawals','program_sessions',
                'program_items','food_versions','food_import_batches','food_batch_versions',
                'food_withdrawals','food_name_versions','food_name_withdrawals','food_name_catalogs']
    writable = ['users','auth_families','refresh_tokens','access_tokens','enrollments',
                'schedule_occurrences','activity_sessions','activity_events','idempotency_records',
                'food_entries','account_deletion_intents']
    statements = []
    if training:
        readonly += ['training_configuration_versions','training_configuration_resources']
        statements.append('GRANT EXECUTE ON FUNCTION trainforge_v1.save_training_configuration(uuid,uuid,bytea,jsonb,uuid),trainforge_v1.erase_training_configuration(uuid,uuid,bytea,bytea) TO trainforge_runtime;')
    if meals:
        readonly += ['meals','meal_items','meal_versions']
        statements.append('GRANT EXECUTE ON FUNCTION trainforge_v1.confirm_meal_group(uuid,uuid,bytea,uuid,integer,text,timestamptz,text,uuid[]),trainforge_v1.delete_meal_group(uuid,uuid,bytea,uuid,integer),trainforge_v1.erase_meals(uuid,uuid,bytea,bytea) TO trainforge_runtime;')
    statements.append('GRANT INSERT,SELECT(erased_at) ON trainforge_v1.account_erasures TO trainforge_runtime; GRANT EXECUTE ON FUNCTION trainforge_v1.erase_private_foods(uuid,uuid,bytea,bytea) TO trainforge_runtime; GRANT EXECUTE ON FUNCTION trainforge_v1.create_private_food(uuid,uuid,bytea,text,text,text,text,text,text,jsonb,jsonb) TO trainforge_runtime;')
    statements.append('GRANT USAGE ON SCHEMA trainforge_v1 TO trainforge_runtime; GRANT SELECT ON '+','.join('trainforge_v1.'+x for x in readonly)+' TO trainforge_runtime; GRANT SELECT,INSERT,UPDATE,DELETE ON '+','.join('trainforge_v1.'+x for x in writable)+' TO trainforge_runtime;')
    return tuple(statements)
