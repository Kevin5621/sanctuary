package dto

type CreateAdvisorFollowUpRequest struct {
	Channel string `json:"channel" binding:"required"`
	Status  string `json:"status" binding:"required"`
	Remark  string `json:"remark" binding:"required"`
}

type AdvisorFollowUpResponse struct {
	ID              string `json:"id"`
	MentorID        string `json:"mentor_id"`
	StudentID       string `json:"student_id"`
	InteractionDate string `json:"interaction_date"`
	Channel         string `json:"channel"`
	Status          string `json:"status"`
	Remark          string `json:"remark"`
	CreatedAt       string `json:"created_at"`
}
