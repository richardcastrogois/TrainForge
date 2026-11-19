package nutrition

import (
	"bytes"
	"errors"
	"image"
	"image/png"
	"testing"
	"trainforge.local/api/internal/privacy"
)

func TestFoodContributionPostgresConsentOwnershipMediaWithdrawalAndErasure(t *testing.T) {
	ctx, writer, runtime := mealPools(t)
	_, p := mealLogin(t, ctx, runtime, "contribution-owner")
	_, other := mealLogin(t, ctx, runtime, "contribution-other")
	store := NutritionStore{runtime}
	in := contributionFixture()
	created, e := store.CreateContribution(ctx, p, in)
	if e != nil || created.Status != "submitted" {
		t.Fatal("contribution", e)
	}
	replay, e := store.CreateContribution(ctx, p, in)
	if e != nil || replay.ID != created.ID {
		t.Fatal("contribution duplicate", e)
	}
	changed := in
	changed.Food.Name = "changed"
	if _, e = store.CreateContribution(ctx, p, changed); !errors.Is(e, ErrEntryConflict) {
		t.Fatal("changed contribution replay")
	}
	if _, e = store.Contribution(ctx, other, created.ID); !errors.Is(e, ErrFoodMissing) {
		t.Fatal("other user's submission visible")
	}
	var picture bytes.Buffer
	_ = png.Encode(&picture, image.NewRGBA(image.Rect(0, 0, 2, 2)))
	withImage, e := store.AttachContributionMedia(ctx, p, created.ID, picture.Bytes(), "image/png")
	if e != nil || len(withImage.Media) != 1 {
		t.Fatal("optional image", e)
	}
	if _, e = store.ContributionMedia(ctx, other, created.ID, withImage.Media[0].ID); !errors.Is(e, ErrFoodMissing) {
		t.Fatal("private photo exposed")
	}
	if repeated, e := store.AttachContributionMedia(ctx, p, created.ID, picture.Bytes(), "image/png"); e != nil || len(repeated.Media) != 1 {
		t.Fatal("duplicate image", e)
	}
	export, e := (privacy.Postgres{Pool: runtime}).Export(ctx, p, privacy.ExportFilter{Section: "foodContributions", Limit: 10})
	if e != nil || len(export.Items) != 1 {
		t.Fatal("contribution export", e)
	}
	withdrawn, e := store.WithdrawContribution(ctx, p, created.ID)
	if e != nil || withdrawn.Status != "withdrawn" || len(withdrawn.Media) != 0 {
		t.Fatal("withdrawal", e)
	}
	if _, e = store.AttachContributionMedia(ctx, p, created.ID, picture.Bytes(), "image/png"); !errors.Is(e, ErrEntryConflict) {
		t.Fatal("withdrawn contribution changed")
	}
	in.OperationID = newID()
	second, e := store.CreateContribution(ctx, p, in)
	if e != nil {
		t.Fatal(e)
	}
	beforeImage, e := ReviewFoodContribution(ctx, writer, second.ID)
	if e != nil {
		t.Fatal("maintainer review", e)
	}
	if _, e = store.AttachContributionMedia(ctx, p, second.ID, picture.Bytes(), "image/png"); e != nil {
		t.Fatal(e)
	}
	if _, e = DecideFoodContribution(ctx, writer, second.ID, "approved", beforeImage.Fingerprint, "label checked"); !errors.Is(e, ErrEntryConflict) {
		t.Fatal("review approved changed evidence")
	}
	review, e := ReviewFoodContribution(ctx, writer, second.ID)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = DecideFoodContribution(ctx, runtime, second.ID, "approved", review.Fingerprint, "label checked"); e == nil {
		t.Fatal("runtime moderation privilege")
	}
	approved, e := DecideFoodContribution(ctx, writer, second.ID, "approved", review.Fingerprint, "label and quantities checked; no clinical approval")
	if e != nil || approved.Contribution.Status != "approved" {
		t.Fatal("explicit maintainer decision", e)
	}
	if _, e = store.WithdrawContribution(ctx, p, second.ID); !errors.Is(e, ErrEntryConflict) {
		t.Fatal("approved publication silently withdrawn")
	}
	var public bytes.Buffer
	if e = ExportApprovedContributions(ctx, writer, &public); e != nil {
		t.Fatal("approved export", e)
	}
	if bytes.Contains(public.Bytes(), []byte(p.User.ID)) || bytes.Contains(public.Bytes(), []byte(in.OperationID)) || bytes.Contains(public.Bytes(), []byte("user_id")) {
		t.Fatal("author identity leaked in public export")
	}
	service := privacy.Service{Repository: privacy.Postgres{Pool: runtime}}
	intent, e := service.Intent(ctx, p, privacy.Confirmation)
	if e != nil {
		t.Fatal("privacy inventory", e)
	}
	if _, e = service.Delete(ctx, p, privacy.DeleteRequest{Confirmation: privacy.Confirmation, Challenge: intent.Challenge}); e != nil {
		t.Fatal("erase contribution", e)
	}
	for _, table := range []string{"food_contributions", "food_contribution_media"} {
		var count int
		if writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1."+table+" WHERE user_id=$1", p.User.ID).Scan(&count) != nil || count != 0 {
			t.Fatal("contribution survived erasure", table)
		}
	}
}
