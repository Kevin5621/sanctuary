package dto

type CreateEmergencyContactRequest struct {
	Name        string `json:"name" binding:"required,min=3,max=128"`
	Phone       string `json:"phone" binding:"required,min=3,max=32"`
	Description string `json:"description" binding:"omitempty,max=500"`
	Is24Hours   bool   `json:"is_24_hours"`
	IsActive    *bool  `json:"is_active" binding:"required"`
	SortOrder   int    `json:"sort_order" binding:"gte=0,lte=999"`
}

type UpdateEmergencyContactRequest struct {
	Name        string `json:"name" binding:"required,min=3,max=128"`
	Phone       string `json:"phone" binding:"required,min=3,max=32"`
	Description string `json:"description" binding:"omitempty,max=500"`
	Is24Hours   bool   `json:"is_24_hours"`
	IsActive    *bool  `json:"is_active" binding:"required"`
	SortOrder   int    `json:"sort_order" binding:"gte=0,lte=999"`
}

type EmergencyContactResponse struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Phone       string `json:"phone"`
	Description string `json:"description,omitempty"`
	Is24Hours   bool   `json:"is_24_hours"`
	IsActive    bool   `json:"is_active"`
	SortOrder   int    `json:"sort_order"`
	UpdatedAt   string `json:"updated_at"`
}
