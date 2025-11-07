import { Rating, Ratings, System, Systems } from '#cds-models/kernseife/db';
import { ZKNSF_I_RATINGS as RatingBTP } from '#cds-models/kernseife_btp';
import { entities, connect, log } from '@sap/cds';

const LOG = log('RatingsFeature');

export const syncRatingsToExternalSystemByRef = async (ref: any) => {
  const system: System = await SELECT.one.from(ref);
  if (!system || !system.destination) {
    throw new Error(
      `System not found or no destination defined for system`
    );
  }

  const ratingsDB: Ratings = await SELECT.from(entities.Ratings).columns(
    getAllRatingColumns
  );

  await syncRatingsToExternalSystem(system, ratingsDB);
};

export const syncRatingsToExternalSystems = async () => {
  const systemList: Systems = await SELECT.from(entities.Systems).where({
    destination: { '!=': null }
  });

  const ratingsDB: Ratings = await SELECT.from(entities.Ratings).columns(
    getAllRatingColumns
  );

  for (const system of systemList) {
    await syncRatingsToExternalSystem(system, ratingsDB);
  }
};

const syncRatingsToExternalSystem = async (
  system: System,
  ratingsDB: Ratings
) => {
  const service = await connect.to('kernseife_btp', {
    credentials: {
      destination: system.destination,
      path: '/sap/opu/odata4/sap/zknsf_btp_connector/srvd/sap/zknsf_btp_connector/0001'
    }
  });
  const { ZKNSF_I_RATINGS } = service.entities;
  const ratingsBTP: RatingBTP[] = await service.run(
    SELECT.from(ZKNSF_I_RATINGS)
  );

  // Delete Ratings which dont exist in local DB anymore
  const ratingsToDelete = ratingsBTP.filter((ratingBTP) => {
    return !ratingsDB.some((ratingDB) => ratingDB.code === ratingBTP.code);
  });
  for (const rating of ratingsToDelete) {
    await service.run(
      DELETE.from(ZKNSF_I_RATINGS).where({ code: rating.code })
    );
    LOG.info(`Deleted Rating ${rating.code}`, rating);
  }

  // Update existing Ratings
  for (const ratingDB of ratingsDB) {
    const updatedRatingBTP = mapRatingsToBTP(ratingDB);
    const ratingBTP = ratingsBTP.find(
      (rating) => rating.code === ratingDB.code
    );
    if (ratingBTP && hasRatingChanged(ratingBTP, updatedRatingBTP)) {
      await service
        .update(ZKNSF_I_RATINGS)
        .set(updatedRatingBTP)
        .where({ code: ratingBTP.code });
      LOG.info(`Updated Rating ${ratingDB.code}`, updatedRatingBTP);
    } else if (!ratingBTP) {
      await service.create(ZKNSF_I_RATINGS, updatedRatingBTP);
      LOG.info(`Inserted Rating ${ratingDB.code}`, updatedRatingBTP);
    } else {
      LOG.info(`No changes for Rating ${ratingDB.code}`);
    }
  }
};

const mapRatingsToBTP = (rating: Rating): RatingBTP => {
  return {
    code: rating.code!,
    criticality: rating.criticality_code || 'E',
    score: rating.score || 0,
    title: rating.title || ''
  };
};

const getAllRatingColumns = (r: any) => {
  r.code;
  r.criticality_code;
  r.score;
  r.title;
};

const hasRatingChanged = (ratingA: RatingBTP, ratingB: RatingBTP) => {
  return (
    ratingA.criticality !== ratingB.criticality ||
    ratingA.score !== ratingB.score ||
    ratingA.title !== ratingB.title
  );
};
