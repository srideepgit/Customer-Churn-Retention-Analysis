// ============================================
// TASK 2 — MONGODB AGGREGATION PIPELINES
// ============================================


// ============================================
// Q1: Calculate average sessions per user per week
//     and 25th, 50th, 75th percentile session durations
// ============================================

db.user_activity_logs.aggregate([
  {
    $match: { session_duration_sec: { $exists: true, $gt: 0 } }
  },
  {
    $addFields: {
      customer_id_clean: {
        $toInt: {
          $ifNull: ["$customer_id", { $ifNull: ["$customerId", "$customerID"] }]
        }
      },
      parsed_ts: { $toDate: "$timestamp" }
    }
  },
  {
    $addFields: {
      week: { $isoWeek: "$parsed_ts" },
      year: { $isoWeekYear: "$parsed_ts" }
    }
  },
  {
    $group: {
      _id: { customer: "$customer_id_clean", week: "$week", year: "$year" },
      sessions: { $sum: 1 },
      durations: { $push: "$session_duration_sec" }
    }
  },
  {
    $group: {
      _id: "$_id.customer",
      avg_sessions_per_week: { $avg: "$sessions" },
      all_durations: { $push: "$durations" }
    }
  },
  {
    $addFields: {
      flat_durations: {
        $reduce: {
          input: "$all_durations",
          initialValue: [],
          in: { $concatArrays: ["$$value", "$$this"] }
        }
      }
    }
  },
  {
    $addFields: {
      sorted: { $sortArray: { input: "$flat_durations", sortBy: 1 } }
    }
  },
  {
    $addFields: {
      n: { $size: "$sorted" },
      p25: { $arrayElemAt: ["$sorted", { $floor: { $multiply: [0.25, { $size: "$sorted" }] } }] },
      p50: { $arrayElemAt: ["$sorted", { $floor: { $multiply: [0.50, { $size: "$sorted" }] } }] },
      p75: { $arrayElemAt: ["$sorted", { $floor: { $multiply: [0.75, { $size: "$sorted" }] } }] }
    }
  },
  {
    $project: {
      _id: 0,
      customer_id: "$_id",
      avg_sessions_per_week: { $round: ["$avg_sessions_per_week", 2] },
      p25_session_duration: "$p25",
      median_session_duration: "$p50",
      p75_session_duration: "$p75"
    }
  },
  { $sort: { avg_sessions_per_week: -1 } }
]);



// ============================================
// Q2: For each feature, compute DAU and 7-day retention
// ============================================

db.user_activity_logs.aggregate([
  {
    $match: {
      event_type: "feature_click",
      feature: { $exists: true, $ne: null }
    }
  },
  {
    $addFields: {
      user_id: { $ifNull: ["$member_id", { $ifNull: ["$userId", "$userID"] }] },
      event_ts: { $toDate: "$timestamp" },
      event_date: {
        $dateToString: { format: "%Y-%m-%d", date: { $toDate: "$timestamp" } }
      }
    }
  },
  {
    $group: {
      _id: { feature: "$feature", user_id: "$user_id" },
      first_use: { $min: "$event_ts" },
      all_events: { $push: "$event_ts" }
    }
  },
  {
    $addFields: {
      returned_7d: {
        $gt: [
          {
            $size: {
              $filter: {
                input: "$all_events",
                as: "d",
                cond: {
                  $and: [
                    { $gt: ["$$d", "$first_use"] },
                    {
                      $lte: [
                        "$$d",
                        { $dateAdd: { startDate: "$first_use", unit: "day", amount: 7 } }
                      ]
                    }
                  ]
                }
              }
            }
          },
          0
        ]
      }
    }
  },
  {
    $group: {
      _id: "$_id.feature",
      users: { $sum: 1 },
      retained: { $sum: { $cond: ["$returned_7d", 1, 0] } }
    }
  },
  {
    $project: {
      _id: 0,
      feature: "$_id",
      total_users: "$users",
      retention_rate_pct: {
        $round: [
          { $multiply: [{ $divide: ["$retained", { $max: ["$users", 1] }] }, 100] },
          1
        ]
      }
    }
  },
  { $sort: { retention_rate_pct: -1 } }
]);



// ============================================
// Q3: Onboarding funnel + drop-offs + median time per step
// ============================================

db.onboarding_events.aggregate([
  {
    $group: {
      _id: "$step",
      users: { $addToSet: "$customer_id" },
      durations: { $push: "$duration_seconds" }
    }
  },
  {
    $project: {
      step: "$_id",
      user_count: { $size: "$users" },
      sorted: { $sortArray: { input: "$durations", sortBy: 1 } }
    }
  },
  {
    $addFields: {
      median_idx: { $floor: { $divide: [{ $size: "$sorted" }, 2] } }
    }
  },
  {
    $project: {
      step: 1,
      user_count: 1,
      median_duration_sec: { $arrayElemAt: ["$sorted", "$median_idx"] }
    }
  }
]);



// ============================================
// Q4: Top 20 engaged users (define engagement score)
// ============================================

db.user_activity_logs.aggregate([
  {
    $addFields: {
      customer_id_clean: {
        $toInt: {
          $ifNull: ["$customer_id", { $ifNull: ["$customerId", "$customerID"] }]
        }
      },
      parsed_ts: { $toDate: "$timestamp" }
    }
  },
  {
    $group: {
      _id: "$customer_id_clean",
      total_events: { $sum: 1 },
      unique_features: { $addToSet: "$feature" },
      avg_session: { $avg: "$session_duration_sec" },
      last_active: { $max: "$parsed_ts" }
    }
  },
  {
    $addFields: {
      feature_count: { $size: "$unique_features" },
      engagement_score: {
        $add: [
          { $multiply: ["$total_events", 0.4] },
          { $multiply: [{ $size: "$unique_features" }, 10] },
          { $multiply: [{ $ifNull: ["$avg_session", 0] }, 0.01] }
        ]
      }
    }
  },
  {
    $project: {
      _id: 0,
      customer_id: "$_id",
      total_events: 1,
      feature_variety: "$feature_count",
      avg_session: 1,
      engagement_score: { $round: ["$engagement_score", 1] },
      last_active: 1
    }
  },
  { $sort: { engagement_score: -1 } },
  { $limit: 20 }
]);